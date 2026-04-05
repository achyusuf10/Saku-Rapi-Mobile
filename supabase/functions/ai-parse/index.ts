/// Supabase Edge Function: ai-parse
///
/// Menerima teks atau gambar dan mengembalikan hasil parsing
/// terstruktur dari AI (Gemini → Groq → OpenRouter failover).
///
/// Mode:
/// - `text`: Parse teks (dari voice STT / input manual) → Gemini → Groq failover
/// - `ocr`: Parse gambar struk (Vision AI) → Gemini → Groq → OpenRouter failover
///
/// Optimizations:
/// - Backend ID mapping: UUID → short ID (e1, i1) di prompt, reverse map di response
/// - System/User prompt split + few-shot examples
/// - Separate timeout: text (8s) vs vision (15s)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY') ?? '';
const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

// Timeout: text models (voice STT / text input)
const GEMINI_TEXT_TIMEOUT_MS = 8000;
const GROQ_TEXT_TIMEOUT_MS = 6000;

// Timeout: vision models (OCR) — proses gambar lebih berat
const GEMINI_VISION_TIMEOUT_MS = 15000;
const GROQ_VISION_TIMEOUT_MS = 15000;
const OPENROUTER_VISION_TIMEOUT_MS = 15000;

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

function buildTextSystemPrompt(): string {
  const today = new Date().toISOString().split('T')[0];

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
11. "note": remaining descriptive text not captured by other fields.

FEW-SHOT EXAMPLES:

Input: "beli makan 25rb pakai gopay"
Output: {"isTransaction":true,"amount":25000,"categoryId":"e1","categoryKeyword":"makan","note":null,"type":"expense","debtLoanKind":null,"suggestedWallet":"GoPay","destinationWallet":null,"withPerson":null,"merchantName":null,"date":null}

Input: "gaji masuk 5.5jt kemarin di BCA"
Output: {"isTransaction":true,"amount":5500000,"categoryId":"i1","categoryKeyword":"gaji","note":null,"type":"income","debtLoanKind":null,"suggestedWallet":"BCA","destinationWallet":null,"withPerson":null,"merchantName":null,"date":"${(() => { const d = new Date(); d.setDate(d.getDate() - 1); return d.toISOString().split('T')[0]; })()}"}

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

function buildOcrSystemPrompt(): string {
  const today = new Date().toISOString().split('T')[0];

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
12. "note": additional context not captured by other fields.

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

// ─────────────────────────────────────────────────────
// AI Provider calls — Text
// ─────────────────────────────────────────────────────

async function callGemini(
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GEMINI_TEXT_TIMEOUT_MS);

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemPrompt }] },
          contents: [{ parts: [{ text: userPrompt }] }],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.1,
          },
        }),
      },
    );

    if (!res.ok) {
      throw new Error(`Gemini HTTP ${res.status}: ${await res.text()}`);
    }

    const json = await res.json();
    const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'gemini' };
  } finally {
    clearTimeout(timeout);
  }
}

async function callGroq(
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GROQ_TEXT_TIMEOUT_MS);

  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.1,
        response_format: { type: 'json_object' },
      }),
    });

    if (!res.ok) {
      throw new Error(`Groq HTTP ${res.status}: ${await res.text()}`);
    }

    const json = await res.json();
    const rawText = json?.choices?.[0]?.message?.content ?? '';
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'groq' };
  } finally {
    clearTimeout(timeout);
  }
}

// ─────────────────────────────────────────────────────
// AI Provider calls — Vision (OCR)
// ─────────────────────────────────────────────────────

async function callGeminiVision(
  base64Image: string,
  mimeType: string,
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GEMINI_VISION_TIMEOUT_MS);

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemPrompt }] },
          contents: [
            {
              parts: [
                { inline_data: { mime_type: mimeType, data: base64Image } },
                { text: userPrompt },
              ],
            },
          ],
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.1,
          },
        }),
      },
    );

    if (!res.ok) {
      throw new Error(`Gemini Vision HTTP ${res.status}: ${await res.text()}`);
    }

    const json = await res.json();
    const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'gemini' };
  } finally {
    clearTimeout(timeout);
  }
}

async function callGroqVision(
  base64Image: string,
  mimeType: string,
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GROQ_VISION_TIMEOUT_MS);

  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'meta-llama/llama-4-scout-17b-16e-instruct',
        messages: [
          { role: 'system', content: systemPrompt },
          {
            role: 'user',
            content: [
              {
                type: 'image_url',
                image_url: { url: `data:${mimeType};base64,${base64Image}` },
              },
              { type: 'text', text: userPrompt },
            ],
          },
        ],
        temperature: 0.1,
        response_format: { type: 'json_object' },
      }),
    });

    if (!res.ok) {
      throw new Error(`Groq Vision HTTP ${res.status}: ${await res.text()}`);
    }

    const json = await res.json();
    const rawText = json?.choices?.[0]?.message?.content ?? '';
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'groq' };
  } finally {
    clearTimeout(timeout);
  }
}

async function callOpenRouterVision(
  base64Image: string,
  mimeType: string,
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENROUTER_VISION_TIMEOUT_MS);

  try {
    const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'google/gemma-3-27b-it:free',
        messages: [
          { role: 'system', content: systemPrompt },
          {
            role: 'user',
            content: [
              {
                type: 'image_url',
                image_url: { url: `data:${mimeType};base64,${base64Image}` },
              },
              { type: 'text', text: userPrompt },
            ],
          },
        ],
        temperature: 0.1,
      }),
    });

    if (!res.ok) {
      throw new Error(`OpenRouter Vision HTTP ${res.status}: ${await res.text()}`);
    }

    const json = await res.json();
    const rawText = json?.choices?.[0]?.message?.content ?? '';
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'openrouter' };
  } finally {
    clearTimeout(timeout);
  }
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
    const mode: string = body.mode; // 'text' | 'ocr'

    if (!mode) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing mode' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (mode !== 'text' && mode !== 'ocr') {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid mode. Use "text" or "ocr".' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Build ID mapping from categories ──
    const categories: CategoryInput[] | undefined = body.categories;
    const mapping = buildIdMapping(categories);

    // ── Try AI providers based on mode ──
    let result: { data: unknown; provider: string };

    if (mode === 'text') {
      const text: string = body.text;
      if (!text) {
        return new Response(
          JSON.stringify({ success: false, error: 'Missing text for text mode' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const systemPrompt = buildTextSystemPrompt();
      const userPrompt = buildTextUserPrompt(text, mapping);

      try {
        result = await callGemini(systemPrompt, userPrompt);
      } catch (geminiErr) {
        console.error('[ai-parse] Gemini failed:', geminiErr);
        try {
          result = await callGroq(systemPrompt, userPrompt);
        } catch (groqErr) {
          console.error('[ai-parse] Groq failed:', groqErr);
          return new Response(
            JSON.stringify({ success: false, mode, error: 'AI_BUSY' }),
            { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          );
        }
      }
    } else {
      const image: string = body.image;
      const mimeType: string = body.mimeType || 'image/jpeg';

      if (!image) {
        return new Response(
          JSON.stringify({ success: false, error: 'Missing image for ocr mode' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const systemPrompt = buildOcrSystemPrompt();
      const userPrompt = buildOcrUserPrompt(mapping);

      try {
        result = await callGeminiVision(image, mimeType, systemPrompt, userPrompt);
      } catch (geminiErr) {
        console.error('[ai-parse] Gemini Vision failed:', geminiErr);
        try {
          result = await callGroqVision(image, mimeType, systemPrompt, userPrompt);
        } catch (groqErr) {
          console.error('[ai-parse] Groq Vision failed:', groqErr);
          try {
            result = await callOpenRouterVision(image, mimeType, systemPrompt, userPrompt);
          } catch (openrouterErr) {
            console.error('[ai-parse] OpenRouter Vision failed:', openrouterErr);
            return new Response(
              JSON.stringify({ success: false, mode, error: 'AI_BUSY' }),
              { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
            );
          }
        }
      }
    }

    // ── Reverse-map short IDs → UUID sebelum kirim ke client ──
    const mappedData = reverseMapResponse(
      result.data as Record<string, unknown>,
      mapping,
    );

    // ── Success response (contract client tetap sama) ──
    return new Response(
      JSON.stringify({
        success: true,
        mode,
        provider: result.provider,
        data: mappedData,
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
