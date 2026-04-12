/// Supabase Edge Function: ai-parse
///
/// Menerima teks atau gambar dan mengembalikan hasil parsing
/// terstruktur dari AI (Vertex AI Gemini only).
///
/// Mode:
/// - `text`: Parse teks (input manual) → Gemini 2.5 Flash Lite via Vertex AI
/// - `voice`: Parse teks (dari voice STT) → Gemini 2.5 Flash Lite via Vertex AI
/// - `ocr`: Parse gambar struk (Vision AI) → Gemini 2.5 Flash via Vertex AI
///
/// Features:
/// - Backend ID mapping: UUID → short ID (e1, i1) di prompt, reverse map di response
/// - System/User prompt split + few-shot examples
/// - Daily quota check (via RPC) before AI call, log after success
/// - Specific error codes: AI_TIMEOUT, AI_RATE_LIMIT, AI_AUTH_ERROR, AI_ERROR, DAILY_QUOTA_EXCEEDED

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const GCP_LOCATION = Deno.env.get('GCP_LOCATION') ?? 'global';
const GCP_SERVICE_ACCOUNT_JSON = Deno.env.get('GCP_SERVICE_ACCOUNT_JSON') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const TEXT_MODEL = 'gemini-2.5-flash-lite';
const VISION_MODEL = 'gemini-2.5-flash';
const GOOGLE_OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const VERTEX_AI_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';

// Timeout: text models (voice STT / text input)
const GEMINI_TEXT_TIMEOUT_MS = 10000;

// Timeout: vision models (OCR) — proses gambar lebih berat
const GEMINI_VISION_TIMEOUT_MS = 20000;

let vertexAccessTokenCache:
  | {
      accessToken: string;
      expiresAtMs: number;
    }
  | null = null;

// ─────────────────────────────────────────────────────
// Category ID mapping: UUID ↔ short ID
// ─────────────────────────────────────────────────────

interface CategoryInput {
  id: string;
  name: string;
  type?: string;
}

interface IdMapping {
  /** Short ID → UUID */
  shortToUuid: Record<string, string>;
  /** UUID → Short ID */
  uuidToShort: Record<string, string>;
  /** Short ID → name, untuk prompt AI */
  promptMap: Record<string, string>;
  /** Expense short IDs (e1, e2, ...) */
  expenseIds: string[];
  /** Income short IDs (i1, i2, ...) */
  incomeIds: string[];
}

function buildIdMapping(categories?: CategoryInput[]): IdMapping {
  const shortToUuid: Record<string, string> = {};
  const uuidToShort: Record<string, string> = {};
  const promptMap: Record<string, string> = {};
  const expenseIds: string[] = [];
  const incomeIds: string[] = [];

  if (!categories || categories.length === 0) {
    return { shortToUuid, uuidToShort, promptMap, expenseIds, incomeIds };
  }

  let expIdx = 1;
  let incIdx = 1;

  for (const cat of categories) {
    const isIncome = cat.type === 'income';
    const shortId = isIncome ? `i${incIdx++}` : `e${expIdx++}`;

    shortToUuid[shortId] = cat.id;
    uuidToShort[cat.id] = shortId;
    promptMap[shortId] = cat.name;

    if (isIncome) {
      incomeIds.push(shortId);
    } else {
      expenseIds.push(shortId);
    }
  }

  return { shortToUuid, uuidToShort, promptMap, expenseIds, incomeIds };
}

/** Reverse-map short IDs di AI response kembali ke UUID asli. */
function reverseMapResponse(
  data: Record<string, unknown>,
  mapping: IdMapping,
): Record<string, unknown> {
  const { shortToUuid } = mapping;
  const result = { ...data };

  // Top-level categoryId
  if (typeof result.categoryId === 'string' && shortToUuid[result.categoryId]) {
    result.categoryId = shortToUuid[result.categoryId];
  } else if (typeof result.categoryId === 'string' && !shortToUuid[result.categoryId]) {
    // AI returned unknown ID → null (safety)
    result.categoryId = null;
  }

  // Per-item categoryId (expense items)
  if (Array.isArray(result.items)) {
    result.items = (result.items as Record<string, unknown>[]).map((item) => {
      const mapped = { ...item };
      if (typeof mapped.categoryId === 'string' && shortToUuid[mapped.categoryId]) {
        mapped.categoryId = shortToUuid[mapped.categoryId];
      } else if (typeof mapped.categoryId === 'string') {
        mapped.categoryId = null;
      }
      return mapped;
    });
  }

  return result;
}

// ─────────────────────────────────────────────────────
// System prompts (shared rules + few-shot)
// ─────────────────────────────────────────────────────

function buildTextSystemPrompt(today: string): string {
  const yesterday = shiftDateString(today, -1);

  return `You are a financial transaction parser for an Indonesian personal finance app. Parse user input text (Indonesian/English) into structured JSON.

OUTPUT FORMAT — return a JSON object with exactly these fields:
{"isTransaction":<bool>,"amount":<number|null>,"categoryId":"<short ID|null>","categoryKeyword":"<lowercase keyword>","note":"<string|null>","type":"<expense|income|transfer|debt|loan>","debtLoanKind":"<debt|loan|debt_payment|loan_collection|null>","suggestedWallet":"<string|null>","destinationWallet":"<string|null>","withPerson":"<string|null>","merchantName":"<string|null>","date":"<yyyy-MM-dd|null>"}

CORE RULES:
1. "isTransaction": true ONLY if input describes a financial event. Random words, greetings, nonsense → false, all other fields null/default.
2. Type detection (default "expense"):
   - income: gaji, terima uang, dapat uang, masuk, bonus, thr, pendapatan, freelance, dividen
   - transfer: transfer, kirim uang, pindah saldo, pindahin, kirim ke
   - debt: hutang, ngutang, pinjem uang, pinjam (BUAT HUTANG BARU — user berhutang ke orang lain)
   - loan: piutang, kasih pinjam, minjemin, dipinjam, kasih hutang (BUAT PIUTANG BARU — orang lain berhutang ke user)
3. "debtLoanKind" — for debt/loan transactions, detect sub-type:
   - "debt": hutang baru (user berhutang, e.g. "hutang ke Budi 50rb", "pinjam uang dari Ani")
   - "loan": piutang baru (orang lain berhutang ke user, e.g. "Budi pinjam 100rb", "kasih pinjam ke Ani")
   - "debt_payment": PELUNASAN hutang (user membayar kembali, e.g. "bayar hutang ke Budi", "lunasi hutang", "cicil hutang Ani 50rb")
   - "loan_collection": PENERIMAAN piutang (orang lain membayar ke user, e.g. "terima piutang dari Budi", "Ani bayar hutang 100rb", "tagih piutang")
   - null: for non-debt/loan types (expense, income, transfer)
4. Amount — convert Indonesian shorthand: "25rb"→25000, "1.5jt"→1500000, "150ribu"→150000, "2juta"→2000000. Return plain number.
5. "categoryId": pick the best matching category short ID from the provided list. ONLY pick IDs whose prefix matches the type (e-prefix for expense, i-prefix for income). For transfer/debt/loan → null.
6. "categoryKeyword": always provide a single lowercase keyword fallback (e.g. makan, transportasi, belanja, gaji).
7. "suggestedWallet": wallet/payment method if mentioned (e.g. "pakai GoPay"→"GoPay", "dari BCA"→"BCA").
8. "destinationWallet": ONLY for transfer (e.g. "transfer dari BCA ke GoPay"→"GoPay").
9. "withPerson": person name for debt/loan and settlements (e.g. "hutang ke Budi"→"Budi", "bayar hutang Ani"→"Ani"). null if none.
10. "date": today is ${today}. Convert: "kemarin"→yesterday, "tadi"/"barusan"→today, "2 hari lalu"→2 days ago, "minggu lalu"→7 days ago. No reference → null.
11. "note": Descriptive name of the item or service being transacted. MUST contain the item/service description (e.g. "Beli Degan", "Makan siang di Warteg", "Bayar listrik"). MUST NOT contain: amount/angka, date/tanggal, wallet name, person name — these belong in their own fields. If the input is just a category keyword with amount (e.g. "makan 25rb"), note should be null.

FEW-SHOT EXAMPLES:

Input: "beli makan 25rb pakai gopay"
Output: {"isTransaction":true,"amount":25000,"categoryId":"e1","categoryKeyword":"makan","note":null,"type":"expense","debtLoanKind":null,"suggestedWallet":"GoPay","destinationWallet":null,"withPerson":null,"merchantName":null,"date":null}

Input: "Beli Degan 10K"
Output: {"isTransaction":true,"amount":10000,"categoryId":"e1","categoryKeyword":"makan","note":"Beli Degan","type":"expense","debtLoanKind":null,"suggestedWallet":null,"destinationWallet":null,"withPerson":null,"merchantName":null,"date":null}

Input: "Beli nasi goreng di warteg kemarin 15rb"
Output: {"isTransaction":true,"amount":15000,"categoryId":"e1","categoryKeyword":"makan","note":"Beli nasi goreng di warteg","type":"expense","debtLoanKind":null,"suggestedWallet":null,"destinationWallet":null,"withPerson":null,"merchantName":null,"date":"${yesterday}"}

Input: "gaji masuk 5.5jt kemarin di BCA"
Output: {"isTransaction":true,"amount":5500000,"categoryId":"i1","categoryKeyword":"gaji","note":null,"type":"income","debtLoanKind":null,"suggestedWallet":"BCA","destinationWallet":null,"withPerson":null,"merchantName":null,"date":"${yesterday}"}

Input: "hutang ke Budi 200rb"
Output: {"isTransaction":true,"amount":200000,"categoryId":null,"categoryKeyword":"hutang","note":null,"type":"debt","debtLoanKind":"debt","suggestedWallet":null,"destinationWallet":null,"withPerson":"Budi","merchantName":null,"date":null}

Input: "bayar hutang ke Ani 150rb"
Output: {"isTransaction":true,"amount":150000,"categoryId":null,"categoryKeyword":"hutang","note":"pelunasan hutang","type":"debt","debtLoanKind":"debt_payment","suggestedWallet":null,"destinationWallet":null,"withPerson":"Ani","merchantName":null,"date":null}

Input: "terima piutang dari Budi 100rb"
Output: {"isTransaction":true,"amount":100000,"categoryId":null,"categoryKeyword":"piutang","note":"penerimaan piutang","type":"loan","debtLoanKind":"loan_collection","suggestedWallet":null,"destinationWallet":null,"withPerson":"Budi","merchantName":null,"date":null}

Return ONLY the JSON object.`;
}

function buildTextUserPrompt(text: string, mapping: IdMapping): string {
  let catSection = '';
  if (Object.keys(mapping.promptMap).length > 0) {
    const mapStr = Object.entries(mapping.promptMap)
      .map(([k, v]) => `"${k}":"${v}"`)
      .join(',');
    catSection = `\nCategories: {${mapStr}}`;
  }
  return `${text}${catSection}`;
}

function buildOcrSystemPrompt(today: string): string {

  return `You are a financial document parser for an Indonesian personal finance app. Analyze receipt/invoice/document images and extract structured JSON.

OUTPUT FORMAT — return a JSON object with exactly these fields:
{"isTransaction":<bool>,"type":"<expense|income|transfer|debt|loan|debt_payment|loan_collection>","merchantName":"<string|null>","date":"<yyyy-MM-dd|null>","grandTotal":<number|null>,"items":[{"name":"<string>","qty":<number>,"unitPrice":<number|null>,"subtotal":<number>,"categoryId":"<short ID|null>"}],"categoryId":"<short ID|null>","categoryKeyword":"<lowercase keyword>","suggestedWallet":"<string|null>","destinationWallet":"<string|null>","withPerson":"<string|null>","note":"<string|null>"}

CORE RULES:
1. "isTransaction": true ONLY if image shows a financial document (receipt, invoice, transfer proof, salary slip, etc). Random photos, memes, selfies → false.
2. Type detection (default "expense"):
   - expense: purchase receipts, bills, invoices
   - income: salary slips, payment received, "LUNAS/PAID" invoices, freelance payment proof
   - transfer: bank/e-wallet transfer proofs ("Transfer berhasil", "Kirim ke ...")
   - debt: IOUs, "hutang" documents, loan agreements where user owes someone (HUTANG BARU)
   - loan: IOUs where someone owes user, "piutang" documents (PIUTANG BARU)
   - debt_payment: proof of paying back a debt ("bayar hutang", "pelunasan", "cicilan hutang")
   - loan_collection: proof of receiving payment for a loan ("terima piutang", "penerimaan piutang", "tagihan dibayar")
3. EXPENSE items: extract line items with name, qty (default 1), unitPrice, subtotal. Ignore tax/discount/change/subtotal summary lines. subtotal = qty × unitPrice.
4. INCOME/TRANSFER/DEBT/LOAN/DEBT_PAYMENT/LOAN_COLLECTION: "items" must be empty array [].
5. "categoryId": for expense items, pick best matching category short ID (e-prefix). For income top-level, pick i-prefix ID. For transfer/debt/loan/debt_payment/loan_collection → null.
6. "categoryKeyword": always provide a single lowercase keyword fallback.
7. All amounts as plain numbers (15000 not "Rp 15.000"). Indonesian patterns: "Rp", "x", "@" for qty/unit.
8. "suggestedWallet": payment method if visible (BCA, GoPay, OVO, DANA, Cash, Tunai).
9. "destinationWallet": ONLY for transfer type.
10. "withPerson": person name for debt/loan/debt_payment/loan_collection.
11. "date": extract as yyyy-MM-dd. Today is ${today}. If not visible → null.
12. "note": Descriptive name of the overall purchase or transaction. MUST NOT contain amounts, dates, wallet names, or person names. Example: "Belanja bulanan Indomaret". If no additional context beyond merchant + items, note should be null.

FEW-SHOT EXAMPLE (expense receipt):
Image shows: "INDOMARET - Coca Cola 2x @8.500 = 17.000, Roti Tawar 1x @12.000 = 12.000, TOTAL: 29.000, TUNAI"
Output: {"isTransaction":true,"type":"expense","merchantName":"INDOMARET","date":null,"grandTotal":29000,"items":[{"name":"Coca Cola","qty":2,"unitPrice":8500,"subtotal":17000,"categoryId":"e1"},{"name":"Roti Tawar","qty":1,"unitPrice":12000,"subtotal":12000,"categoryId":"e1"}],"categoryId":null,"categoryKeyword":"belanja","suggestedWallet":"Tunai","destinationWallet":null,"withPerson":null,"note":null}

Return ONLY the JSON object.`;
}

function buildOcrUserPrompt(mapping: IdMapping): string {
  if (Object.keys(mapping.promptMap).length === 0) {
    return 'Parse this receipt/document image.';
  }
  const mapStr = Object.entries(mapping.promptMap)
    .map(([k, v]) => `"${k}":"${v}"`)
    .join(',');
  return `Parse this receipt/document image.\nCategories: {${mapStr}}`;
}

// ─────────────────────────────────────────────────────
// JSON sanitizer — strip markdown code fences
// ─────────────────────────────────────────────────────

function sanitizeJson(raw: string): string {
  let cleaned = raw.trim();
  cleaned = cleaned.replace(/^```(?:json)?\s*\n?/i, '');
  cleaned = cleaned.replace(/\n?```\s*$/i, '');
  return cleaned.trim();
}

const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function getUtcDateString(): string {
  return new Date().toISOString().split('T')[0];
}

function resolvePromptDate(localDate: unknown): string {
  if (typeof localDate === 'string' && DATE_ONLY_PATTERN.test(localDate)) {
    return localDate;
  }
  return getUtcDateString();
}

function shiftDateString(dateString: string, days: number): string {
  const [year, month, day] = dateString.split('-').map((value) => Number(value));
  const date = new Date(Date.UTC(year, month - 1, day));
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().split('T')[0];
}

function encodeBase64Url(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleanPem = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binary = atob(cleanPem);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

function getServiceAccountCredentials(): {
  projectId: string;
  clientEmail: string;
  privateKey: string;
} {
  if (!GCP_SERVICE_ACCOUNT_JSON) {
    throw new Error('Vertex AI credentials are not configured. Set GCP_SERVICE_ACCOUNT_JSON.');
  }

  const parsed = JSON.parse(GCP_SERVICE_ACCOUNT_JSON) as {
    project_id?: string;
    client_email?: string;
    private_key?: string;
  };

  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error(
      'GCP_SERVICE_ACCOUNT_JSON is invalid. Required fields: project_id, client_email, private_key.',
    );
  }

  return {
    projectId: parsed.project_id,
    clientEmail: parsed.client_email,
    privateKey: parsed.private_key.replace(/\\n/g, '\n'),
  };
}

async function signServiceAccountJwt(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: clientEmail,
    scope: VERTEX_AI_SCOPE,
    aud: GOOGLE_OAUTH_TOKEN_URL,
    exp: now + 3600,
    iat: now,
  };
  const unsignedToken = `${encodeBase64Url(JSON.stringify(header))}.${encodeBase64Url(
    JSON.stringify(payload),
  )}`;
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKey),
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsignedToken),
  );

  return `${unsignedToken}.${encodeBase64Url(new Uint8Array(signature))}`;
}

async function getVertexAccessToken(): Promise<string> {
  if (vertexAccessTokenCache && vertexAccessTokenCache.expiresAtMs > Date.now() + 60_000) {
    return vertexAccessTokenCache.accessToken;
  }

  const { clientEmail, privateKey } = getServiceAccountCredentials();
  const assertion = await signServiceAccountJwt(clientEmail, privateKey);
  const tokenResponse = await fetch(GOOGLE_OAUTH_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!tokenResponse.ok) {
    throw new Error(`Vertex auth HTTP ${tokenResponse.status}: ${await tokenResponse.text()}`);
  }

  const tokenJson = (await tokenResponse.json()) as {
    access_token?: string;
    expires_in?: number;
  };

  if (!tokenJson.access_token || !tokenJson.expires_in) {
    throw new Error('Vertex auth response is missing access_token or expires_in.');
  }

  vertexAccessTokenCache = {
    accessToken: tokenJson.access_token,
    expiresAtMs: Date.now() + tokenJson.expires_in * 1000,
  };

  return tokenJson.access_token;
}

function buildVertexGenerateContentUrl(model: string): string {
  const { projectId } = getServiceAccountCredentials();
  return `https://aiplatform.googleapis.com/v1/projects/${projectId}/locations/${GCP_LOCATION}/publishers/google/models/${model}:generateContent`;
}

function extractResponseText(json: Record<string, unknown>): string {
  const candidates = json.candidates as Array<Record<string, unknown>> | undefined;
  const parts =
    (candidates?.[0]?.content as Record<string, unknown> | undefined)?.parts as
      | Array<Record<string, unknown>>
      | undefined;

  return (
    parts
      ?.map((part) => (typeof part.text === 'string' ? part.text : ''))
      .join('')
      .trim() ?? ''
  );
}

async function callVertexGenerateContent({
  model,
  timeoutMs,
  systemPrompt,
  parts,
}: {
  model: string;
  timeoutMs: number;
  systemPrompt: string;
  parts: Array<Record<string, unknown>>;
}): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const accessToken = await getVertexAccessToken();
    const res = await fetch(buildVertexGenerateContentUrl(model), {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      signal: controller.signal,
      body: JSON.stringify({
        systemInstruction: {
          role: 'system',
          parts: [{ text: systemPrompt }],
        },
        contents: [
          {
            role: 'user',
            parts,
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.1,
        },
      }),
    });

    if (!res.ok) {
      throw new Error(`Vertex AI HTTP ${res.status}: ${await res.text()}`);
    }

    const json = (await res.json()) as Record<string, unknown>;
    const rawText = extractResponseText(json);
    return { data: JSON.parse(sanitizeJson(rawText)), provider: model };
  } finally {
    clearTimeout(timeout);
  }
}

// ─────────────────────────────────────────────────────
// AI Provider calls — Text
// ─────────────────────────────────────────────────────

async function callVertexText(
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  return callVertexGenerateContent({
    model: TEXT_MODEL,
    timeoutMs: GEMINI_TEXT_TIMEOUT_MS,
    systemPrompt,
    parts: [{ text: userPrompt }],
  });
}

// ─────────────────────────────────────────────────────
// AI Provider calls — Vision (OCR)
// ─────────────────────────────────────────────────────

async function callVertexVision(
  base64Image: string,
  mimeType: string,
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  return callVertexGenerateContent({
    model: VISION_MODEL,
    timeoutMs: GEMINI_VISION_TIMEOUT_MS,
    systemPrompt,
    parts: [
      {
        inlineData: {
          mimeType,
          data: base64Image,
        },
      },
      { text: userPrompt },
    ],
  });
}

// ─────────────────────────────────────────────────────
// Error classification — specific error codes
// ─────────────────────────────────────────────────────

function classifyError(err: unknown): { code: string; message: string; status: number } {
  const errMsg = err instanceof Error ? err.message : String(err);

  if (errMsg.includes('aborted') || errMsg.includes('AbortError') || errMsg.includes('timeout')) {
    return { code: 'AI_TIMEOUT', message: 'AI request timed out. Please try again.', status: 504 };
  }
  if (
    errMsg.includes('404') ||
    errMsg.includes('not found') ||
    errMsg.includes('Vertex AI credentials are not configured') ||
    errMsg.includes('GCP_SERVICE_ACCOUNT_JSON is invalid')
  ) {
    return {
      code: 'AI_CONFIG_ERROR',
      message: 'AI service configuration error. Please contact support.',
      status: 502,
    };
  }
  if (errMsg.includes('429') || errMsg.includes('rate limit') || errMsg.includes('RESOURCE_EXHAUSTED')) {
    return { code: 'AI_RATE_LIMIT', message: 'AI service is rate limited. Please wait a moment.', status: 429 };
  }
  if (errMsg.includes('401') || errMsg.includes('403') || errMsg.includes('PERMISSION_DENIED')) {
    return { code: 'AI_AUTH_ERROR', message: 'AI service authentication error.', status: 502 };
  }
  return { code: 'AI_ERROR', message: `AI processing failed: ${errMsg}`, status: 503 };
}

// ─────────────────────────────────────────────────────
// CORS helpers
// ─────────────────────────────────────────────────────

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ─────────────────────────────────────────────────────
// Main handler
// ─────────────────────────────────────────────────────

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ── JWT Validation ──
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Parse request body ──
    const body = await req.json();
    const mode: string = body.mode; // 'text' | 'voice' | 'ocr'

    if (!mode) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing mode' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (mode !== 'text' && mode !== 'voice' && mode !== 'ocr') {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid mode. Use "text", "voice", or "ocr".' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const localDate = resolvePromptDate(body.localDate);

    // ── Quota check (before AI call) ──
    const { data: quotaData, error: quotaError } = await supabase.rpc('check_ai_quota', {
      p_mode: mode,
      p_usage_date: localDate,
    });

    if (quotaError) {
      console.error('[ai-parse] Quota check error:', quotaError);
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to check quota' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!quotaData?.allowed) {
      return new Response(
        JSON.stringify({
          success: false,
          mode,
          error: 'DAILY_QUOTA_EXCEEDED',
          message: 'Batas harian tercapai. Coba lagi besok.',
          quota: {
            used: quotaData?.used ?? 0,
            limit: quotaData?.limit ?? 0,
            remaining: 0,
            tier: quotaData?.tier ?? 'free',
          },
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Build ID mapping from categories ──
    const categories: CategoryInput[] | undefined = body.categories;
    const mapping = buildIdMapping(categories);

    // ── Call AI based on mode ──
    let result: { data: unknown; provider: string };

    if (mode === 'text' || mode === 'voice') {
      // text and voice use the same text pipeline
      const text: string = body.text;
      if (!text) {
        return new Response(
          JSON.stringify({ success: false, error: 'Missing text for text/voice mode' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const systemPrompt = buildTextSystemPrompt(localDate);
      const userPrompt = buildTextUserPrompt(text, mapping);

      try {
        result = await callVertexText(systemPrompt, userPrompt);
      } catch (err) {
        console.error('[ai-parse] Vertex text failed:', err);
        const classified = classifyError(err);
        return new Response(
          JSON.stringify({ success: false, mode, error: classified.code, message: classified.message }),
          { status: classified.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }
    } else {
      // ocr mode
      const image: string = body.image;
      const mimeType: string = body.mimeType || 'image/jpeg';

      if (!image) {
        return new Response(
          JSON.stringify({ success: false, error: 'Missing image for ocr mode' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const systemPrompt = buildOcrSystemPrompt(localDate);
      const userPrompt = buildOcrUserPrompt(mapping);

      try {
        result = await callVertexVision(image, mimeType, systemPrompt, userPrompt);
      } catch (err) {
        console.error('[ai-parse] Vertex vision failed:', err);
        const classified = classifyError(err);
        return new Response(
          JSON.stringify({ success: false, mode, error: classified.code, message: classified.message }),
          { status: classified.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }
    }

    // ── Log usage (after AI success) ──
    const { data: usageData, error: usageError } = await supabase.rpc('log_ai_usage', {
      p_mode: mode,
      p_provider: result.provider,
      p_usage_date: localDate,
    });

    if (usageError) {
      console.error('[ai-parse] Log usage error (non-blocking):', usageError);
    }

    // ── Reverse-map short IDs → UUID sebelum kirim ke client ──
    const mappedData = reverseMapResponse(
      result.data as Record<string, unknown>,
      mapping,
    );

    // ── Success response ──
    return new Response(
      JSON.stringify({
        success: true,
        mode,
        provider: result.provider,
        data: mappedData,
        quota: {
          used: usageData?.used ?? null,
          limit: usageData?.limit ?? null,
          remaining: usageData?.remaining ?? null,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('[ai-parse] Unhandled error:', err);
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
