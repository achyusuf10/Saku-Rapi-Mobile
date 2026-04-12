/// Supabase Edge Function: gold-price
///
/// Cronjob (09:00 WIB / 02:00 UTC daily) untuk mengambil harga emas
/// dari antaremas.com dan logammulia.com → INSERT ke gold_prices.
///
/// Strategy:
/// - Thread 1 (Antaremas): WordPress REST API → Regex extract → Vertex AI fallback
/// - Thread 2 (LogamMulia): HTML parsing → Vertex AI fallback
/// - AI provider: Vertex AI Gemini 2.5 Flash only
/// - Validation: All prices must be > 1,000,000 per gram

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const GCP_LOCATION = Deno.env.get('GCP_LOCATION') ?? 'global';
const GCP_SERVICE_ACCOUNT_JSON = Deno.env.get('GCP_SERVICE_ACCOUNT_JSON') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const GEMINI_MODEL = 'gemini-2.5-flash';
const GOOGLE_OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const VERTEX_AI_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';

const AI_TIMEOUT_MS = 20000;
const SOURCE_TIMEOUT_MS = 10000;
const MIN_GOLD_PRICE = 1_000_000;
const MAX_GOLD_PRICE = 10_000_000;

interface GoldPrice {
  buy: number;
  sell: number;
}

let vertexAccessTokenCache:
  | {
      accessToken: string;
      expiresAtMs: number;
    }
  | null = null;

const debugLogs: string[] = [];

function isValidPrice(price: number): boolean {
  return price >= MIN_GOLD_PRICE && price <= MAX_GOLD_PRICE;
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

function buildVertexGenerateContentUrl(): string {
  const { projectId } = getServiceAccountCredentials();
  return `https://aiplatform.googleapis.com/v1/projects/${projectId}/locations/${GCP_LOCATION}/publishers/google/models/${GEMINI_MODEL}:generateContent`;
}

function extractResponseText(json: Record<string, unknown>): string {
  const candidates = json.candidates as Array<Record<string, unknown>> | undefined;
  const content = candidates?.[0]?.content as Record<string, unknown> | undefined;
  const parts = content?.parts as Array<Record<string, unknown>> | undefined;

  return (
    parts
      ?.map((part) => (typeof part.text === 'string' ? part.text : ''))
      .join('')
      .trim() ?? ''
  );
}

async function callGeminiText(prompt: string): Promise<string | null> {
  try {
    const accessToken = await getVertexAccessToken();
    const res = await fetch(buildVertexGenerateContentUrl(), {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      signal: AbortSignal.timeout(AI_TIMEOUT_MS),
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }],
          },
        ],
        generationConfig: { temperature: 0.1 },
      }),
    });

    if (!res.ok) {
      debugLogs.push(`vertex_text_http_error: ${res.status}`);
      debugLogs.push(`vertex_text_http_body: ${(await res.text()).substring(0, 300)}`);
      return null;
    }

    const data = (await res.json()) as Record<string, unknown>;
    return extractResponseText(data);
  } catch (err) {
    debugLogs.push(`vertex_text_error: ${String(err)}`);
    return null;
  }
}

async function callGeminiWithSearch(
  systemPrompt: string,
  userPrompt: string,
): Promise<string | null> {
  try {
    const accessToken = await getVertexAccessToken();
    const res = await fetch(buildVertexGenerateContentUrl(), {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      signal: AbortSignal.timeout(AI_TIMEOUT_MS),
      body: JSON.stringify({
        systemInstruction: {
          role: 'system',
          parts: [{ text: systemPrompt }],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: userPrompt }],
          },
        ],
        tools: [{ googleSearch: {} }],
        generationConfig: { temperature: 0.1 },
      }),
    });

    if (!res.ok) {
      debugLogs.push(`vertex_search_http_error: ${res.status}`);
      debugLogs.push(`vertex_search_http_body: ${(await res.text()).substring(0, 300)}`);
      return null;
    }

    const data = (await res.json()) as Record<string, unknown>;
    return extractResponseText(data);
  } catch (err) {
    debugLogs.push(`vertex_search_error: ${String(err)}`);
    return null;
  }
}

function parseJsonFromAI(text: string): GoldPrice | null {
  try {
    const jsonMatch = text.match(/\{[^}]*"buy"\s*:\s*\d+[^}]*"sell"\s*:\s*\d+[^}]*\}/);
    if (!jsonMatch) {
      const altMatch = text.match(/\{[^}]*"sell"\s*:\s*\d+[^}]*"buy"\s*:\s*\d+[^}]*\}/);
      if (!altMatch) return null;
      const parsed = JSON.parse(altMatch[0]);
      if (typeof parsed.buy === 'number' && typeof parsed.sell === 'number') {
        return parsed as GoldPrice;
      }
      return null;
    }
    const parsed = JSON.parse(jsonMatch[0]);
    if (typeof parsed.buy === 'number' && typeof parsed.sell === 'number') {
      return parsed as GoldPrice;
    }
    return null;
  } catch {
    return null;
  }
}

function validateGoldPrice(price: GoldPrice | null): GoldPrice | null {
  if (!price) return null;
  if (!isValidPrice(price.buy) || !isValidPrice(price.sell)) return null;
  if (price.sell <= price.buy) return null;
  return price;
}

function parseAntaremasHtml(html: string): GoldPrice | null {
  debugLogs.push(`antaremas_html_len: ${html.length}`);

  let buy = 0;
  let sell = 0;

  const buybackMatch = html.match(
    /Buyback\s+per\s+1\s+Gr<\/td>\s*<td[^>]*>Rp\.\s*([\d.]+)/i,
  );
  debugLogs.push(`antaremas_buyback_match: ${buybackMatch ? buybackMatch[1] : 'null'}`);
  if (buybackMatch) {
    buy = parseInt(buybackMatch[1].replace(/\./g, ''), 10);
  }

  const dataPriceMatch = html.match(/name="1_gram"[^>]*data-price="(\d+)"/);
  debugLogs.push(`antaremas_dataprice_match: ${dataPriceMatch ? dataPriceMatch[1] : 'null'}`);
  if (dataPriceMatch) {
    sell = parseInt(dataPriceMatch[1], 10);
  }

  if (!sell) {
    const sellMatch = html.match(/<td>1\s+gram<\/td>\s*<td>Rp\.\s*([\d.]+)/i);
    debugLogs.push(`antaremas_sell_match: ${sellMatch ? sellMatch[1] : 'null'}`);
    if (sellMatch) {
      sell = parseInt(sellMatch[1].replace(/\./g, ''), 10);
    }
  }

  debugLogs.push(`antaremas_parsed: buy=${buy}, sell=${sell}`);
  const result = validateGoldPrice({ buy, sell });
  debugLogs.push(`antaremas_validated: ${result ? 'pass' : 'fail'}`);
  return result;
}

function getTodayDateWIB(): string {
  const now = new Date();
  const wib = new Date(now.getTime() + 7 * 60 * 60 * 1000);
  return wib.toISOString().split('T')[0];
}

const ANTAREMAS_SYSTEM_PROMPT = `Cari harga emas Antam per 1 gram HARI INI dalam Rupiah (IDR) dari antaremas.com.
Ada 2 harga yang perlu:
1. "buy" = harga BUYBACK per 1 Gr (harga beli kembali oleh toko, di tabel "TABEL HARGA BUYBACK" baris "Buyback per 1 Gr")
2. "sell" = harga JUAL 1 gram (harga yang dibayar pembeli, di tabel harga jual baris "1 gram")

PENTING:
- sell HARUS lebih tinggi dari buy
- Keduanya integer dalam IDR (tanpa titik pemisah)
- Harga wajar sekitar Rp 2-4 juta per gram

Return ONLY JSON: {"buy": <number>, "sell": <number>}
Contoh: {"buy": 2722000, "sell": 3162000}`;

async function fetchAntaremas(): Promise<GoldPrice | null> {
  const wpApiHeaders = {
    Accept: 'application/json',
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  };

  try {
    const res = await fetch('https://antaremas.com/wp-json/wp/v2/pages?slug=harga-emas', {
      signal: AbortSignal.timeout(SOURCE_TIMEOUT_MS),
      headers: wpApiHeaders,
    });

    debugLogs.push(`antaremas_wp1_status: ${res.status}`);

    if (res.ok) {
      const data = await res.json();
      debugLogs.push(`antaremas_wp1_data_len: ${data?.length}`);
      if (data?.[0]?.content?.rendered) {
        const result = parseAntaremasHtml(data[0].content.rendered);
        if (result) return result;
      }
    }
  } catch (err) {
    debugLogs.push(`antaremas_wp1_error: ${String(err)}`);
  }

  try {
    const res = await fetch('https://www.antaremas.com/wp-json/wp/v2/pages?slug=harga-emas', {
      signal: AbortSignal.timeout(SOURCE_TIMEOUT_MS),
      headers: wpApiHeaders,
    });

    debugLogs.push(`antaremas_wp2_status: ${res.status}`);

    if (res.ok) {
      const data = await res.json();
      if (data?.[0]?.content?.rendered) {
        const result = parseAntaremasHtml(data[0].content.rendered);
        if (result) return result;
      }
    }
  } catch (err) {
    debugLogs.push(`antaremas_wp2_error: ${String(err)}`);
  }

  try {
    const res = await fetch('https://antaremas.com/harga-emas/', {
      signal: AbortSignal.timeout(SOURCE_TIMEOUT_MS),
      headers: {
        ...wpApiHeaders,
        Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    });

    debugLogs.push(`antaremas_page_status: ${res.status}`);

    if (res.ok) {
      const html = await res.text();
      const result = parseAntaremasHtml(html);
      if (result) return result;
    }
  } catch (err) {
    debugLogs.push(`antaremas_page_error: ${String(err)}`);
  }

  debugLogs.push('antaremas: falling through to Vertex AI');

  const todayWIB = getTodayDateWIB();
  const userPrompt = `Cari harga emas Antam dari antaremas.com untuk HARI INI tanggal ${todayWIB}. HARUS harga tanggal ${todayWIB}, bukan tanggal lain.`;

  const searchResult = await callGeminiWithSearch(ANTAREMAS_SYSTEM_PROMPT, userPrompt);
  if (searchResult) {
    debugLogs.push(`antaremas_ai_search_raw: ${searchResult.substring(0, 200)}`);
    const result = validateGoldPrice(parseJsonFromAI(searchResult));
    if (result) return result;
  }

  const prompt = `${ANTAREMAS_SYSTEM_PROMPT}\n\nHari ini: ${todayWIB}`;
  const text = await callGeminiText(prompt);
  if (text) {
    debugLogs.push(`antaremas_ai_plain_raw: ${text.substring(0, 200)}`);
    const result = validateGoldPrice(parseJsonFromAI(text));
    if (result) return result;
  }

  return null;
}

async function fetchLogamMulia(): Promise<GoldPrice | null> {
  try {
    const res = await fetch('https://harga-emas.org/', {
      signal: AbortSignal.timeout(SOURCE_TIMEOUT_MS),
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        Accept: 'text/html,*/*',
        'Accept-Language': 'id-ID,id;q=0.9',
      },
    });

    debugLogs.push(`hargaemas_status: ${res.status}`);

    if (res.ok) {
      const html = await res.text();
      debugLogs.push(`hargaemas_len: ${html.length}`);

      let buy = 0;
      let sell = 0;

      const buybackMatch = html.match(/pembelian\s+kembali[^R]*Rp\s*([\d.,]+)/i);
      debugLogs.push(`hargaemas_buyback_match: ${buybackMatch ? buybackMatch[1] : 'null'}`);
      if (buybackMatch) {
        buy = parseInt(buybackMatch[1].replace(/[.,]/g, ''), 10);
      }

      const idx1g = html.indexOf('>1<');
      debugLogs.push(`hargaemas_1g_idx: ${idx1g}`);
      if (idx1g >= 0) {
        debugLogs.push(
          `hargaemas_1g_ctx: ${html.substring(idx1g, idx1g + 200).replace(/\n/g, ' ')}`,
        );
      }

      const priceIdx = html.search(/\d\.\d{3}\.\d{3}/);
      debugLogs.push(`hargaemas_price_idx: ${priceIdx}`);
      if (priceIdx >= 0) {
        debugLogs.push(
          `hargaemas_price_ctx: ${html
            .substring(Math.max(0, priceIdx - 50), priceIdx + 50)
            .replace(/\n/g, ' ')}`,
        );
      }

      const sellP1 = html.match(
        />\s*1\s*<\/p>\s*<\/td>\s*<td[^>]*>\s*<div[^>]*>\s*<p>\s*([\d.]{7,})\s*<\/p>/i,
      );
      debugLogs.push(`hargaemas_sell_p1: ${sellP1 ? sellP1[1] : 'null'}`);

      const sellP2 = html.match(/<td[^>]*>\s*1\s*<\/td>\s*<td[^>]*>\s*([\d.]{7,})\s*<\/td>/i);
      debugLogs.push(`hargaemas_sell_p2: ${sellP2 ? sellP2[1] : 'null'}`);

      const sellP3 = html.match(/>\s*1\s*<[\s\S]{0,200}?>\s*(\d\.\d{3}\.\d{3})\s*</);
      debugLogs.push(`hargaemas_sell_p3: ${sellP3 ? sellP3[1] : 'null'}`);

      const sellStr = sellP1?.[1] ?? sellP2?.[1] ?? sellP3?.[1];
      if (sellStr) {
        sell = parseInt(sellStr.replace(/\./g, ''), 10);
      }

      debugLogs.push(`hargaemas_parsed: buy=${buy}, sell=${sell}`);
      const result = validateGoldPrice({ buy, sell });
      debugLogs.push(`hargaemas_validated: ${result ? 'pass' : 'fail'}`);
      if (result) return result;
    }
  } catch (err) {
    debugLogs.push(`hargaemas_error: ${String(err)}`);
  }

  const todayLM = getTodayDateWIB();
  const lmSystemPrompt = `Cari harga emas ANTAM Logam Mulia per 1 gram HARI INI (${todayLM}).
1. "buy" = Harga Buyback per gram (harga ANTAM beli kembali)
2. "sell" = Harga jual emas batangan 1 gram (harga pembeli bayar)
sell > buy. Integers dalam IDR. Harga wajar ~Rp 2-4 juta.
Return ONLY JSON: {"buy": <number>, "sell": <number>}`;
  const lmUserPrompt = `Cari harga emas ANTAM Logam Mulia untuk HARI INI tanggal ${todayLM} dari logammulia.com.`;

  const searchResult = await callGeminiWithSearch(lmSystemPrompt, lmUserPrompt);
  if (searchResult) {
    debugLogs.push(`logammulia_ai_search_raw: ${searchResult.substring(0, 200)}`);
    const result = validateGoldPrice(parseJsonFromAI(searchResult));
    if (result) return result;
  }

  const prompt = `You are a JSON-only data extractor. Based on your latest knowledge of logammulia.com (PT ANTAM Logam Mulia) gold prices today, extract:
- "buy" = harga buyback per gram (from the sell/buyback page)
- "sell" = harga jual emas batangan 1 gram (from the purchase page)

IMPORTANT: sell must be HIGHER than buy. Both are integers in IDR (e.g., 2500000).
Output ONLY valid JSON: {"buy": <number>, "sell": <number>}`;
  const text = await callGeminiText(prompt);
  if (text) {
    debugLogs.push(`logammulia_ai_plain_raw: ${text.substring(0, 200)}`);
    const result = validateGoldPrice(parseJsonFromAI(text));
    if (result) return result;
  }

  return null;
}

Deno.serve(async (req) => {
  debugLogs.length = 0;

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const [antaremas, logamMulia] = await Promise.all([fetchAntaremas(), fetchLogamMulia()]);

    const results: { source: string; status: string; prices?: GoldPrice }[] = [];
    const url = new URL(req.url);
    const debugMode = url.searchParams.get('debug') === '1';

    if (antaremas) {
      if (!debugMode) {
        const { error } = await supabase.from('gold_prices').insert({
          source: 'antaremas',
          buy_price: antaremas.buy,
          sell_price: antaremas.sell,
        });
        results.push({
          source: 'antaremas',
          status: error ? `error: ${error.message}` : 'inserted',
          prices: antaremas,
        });
      } else {
        results.push({ source: 'antaremas', status: 'debug_skip', prices: antaremas });
      }
    } else {
      results.push({ source: 'antaremas', status: 'fetch_failed' });
    }

    if (logamMulia) {
      if (!debugMode) {
        const { error } = await supabase.from('gold_prices').insert({
          source: 'logammulia',
          buy_price: logamMulia.buy,
          sell_price: logamMulia.sell,
        });
        results.push({
          source: 'logammulia',
          status: error ? `error: ${error.message}` : 'inserted',
          prices: logamMulia,
        });
      } else {
        results.push({ source: 'logammulia', status: 'debug_skip', prices: logamMulia });
      }
    } else {
      results.push({ source: 'logammulia', status: 'fetch_failed' });
    }

    return new Response(
      JSON.stringify({ success: true, results, ...(debugMode ? { debug: debugLogs } : {}) }),
      {
        headers: { 'Content-Type': 'application/json' },
      },
    );
  } catch (err) {
    return new Response(JSON.stringify({ success: false, error: String(err), debug: debugLogs }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
