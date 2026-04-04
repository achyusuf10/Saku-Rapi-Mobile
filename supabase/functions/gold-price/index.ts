/// Supabase Edge Function: gold-price
///
/// Cronjob (09:00 WIB / 02:00 UTC daily) untuk mengambil harga emas
/// dari antaremas.com dan logammulia.com → INSERT ke gold_prices.
///
/// Strategy:
/// - Thread 1 (Antaremas): WordPress REST API → Regex extract → AI Fallback
/// - Thread 2 (LogamMulia): Gemini + Google Search grounding → AI Fallback
/// - AI Fallback Chain: Gemini → Groq → OpenRouter
/// - Validation: All prices must be > 1,000,000 per gram

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY') ?? '';
const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const AI_TIMEOUT_MS = 20000;
const MIN_GOLD_PRICE = 1_000_000;
const MAX_GOLD_PRICE = 10_000_000;

interface GoldPrice {
  buy: number;
  sell: number;
}

function isValidPrice(price: number): boolean {
  return price >= MIN_GOLD_PRICE && price <= MAX_GOLD_PRICE;
}

// ─────────────────────────────────────────────────────
// AI Provider Helpers
// ─────────────────────────────────────────────────────

async function callGemini(prompt: string): Promise<string | null> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(AI_TIMEOUT_MS),
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.1 },
        }),
      }
    );

    if (!res.ok) return null;
    const data = await res.json();
    return data?.candidates?.[0]?.content?.parts?.[0]?.text ?? null;
  } catch {
    return null;
  }
}

async function callGeminiWithSearch(systemPrompt: string, userPrompt: string): Promise<string | null> {
  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(AI_TIMEOUT_MS),
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemPrompt }] },
          contents: [{ parts: [{ text: userPrompt }] }],
          tools: [{ google_search: {} }],
          generationConfig: { temperature: 0.1 },
        }),
      }
    );

    if (!res.ok) return null;
    const data = await res.json();
    const parts = data?.candidates?.[0]?.content?.parts;
    if (!parts) return null;
    return parts.map((p: { text?: string }) => p.text ?? '').join('');
  } catch {
    return null;
  }
}

async function callGroq(prompt: string): Promise<string | null> {
  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      signal: AbortSignal.timeout(AI_TIMEOUT_MS),
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0,
      }),
    });

    if (!res.ok) return null;
    const data = await res.json();
    return data?.choices?.[0]?.message?.content ?? null;
  } catch {
    return null;
  }
}

async function callOpenRouter(prompt: string): Promise<string | null> {
  try {
    const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
      },
      signal: AbortSignal.timeout(AI_TIMEOUT_MS),
      body: JSON.stringify({
        model: 'google/gemini-2.0-flash-001',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0,
      }),
    });

    if (!res.ok) return null;
    const data = await res.json();
    return data?.choices?.[0]?.message?.content ?? null;
  } catch {
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

// ─────────────────────────────────────────────────────
// Source Fetchers
// ─────────────────────────────────────────────────────

const debugLogs: string[] = [];

function parseAntaremasHtml(html: string): GoldPrice | null {
  debugLogs.push(`antaremas_html_len: ${html.length}`);

  let buy = 0;
  let sell = 0;

  // buy_price: "Buyback per 1 Gr" → next <td> → Rp. X.XXX.XXX
  const buybackMatch = html.match(
    /Buyback\s+per\s+1\s+Gr<\/td>\s*<td[^>]*>Rp\.\s*([\d.]+)/i
  );
  debugLogs.push(`antaremas_buyback_match: ${buybackMatch ? buybackMatch[1] : 'null'}`);
  if (buybackMatch) {
    buy = parseInt(buybackMatch[1].replace(/\./g, ''), 10);
  }

  // sell_price method 1: data-price from simulation input (most reliable)
  const dataPriceMatch = html.match(
    /name="1_gram"[^>]*data-price="(\d+)"/
  );
  debugLogs.push(`antaremas_dataprice_match: ${dataPriceMatch ? dataPriceMatch[1] : 'null'}`);
  if (dataPriceMatch) {
    sell = parseInt(dataPriceMatch[1], 10);
  }

  // sell_price method 2: <td>1 gram</td> → next <td> → Rp. X.XXX.XXX
  if (!sell) {
    const sellMatch = html.match(
      /<td>1\s+gram<\/td>\s*<td>Rp\.\s*([\d.]+)/i
    );
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
  // Headers matching the old working script: Accept: application/json
  const wpApiHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  };

  // Attempt 1: WP REST API WITHOUT www. (old working script used this URL)
  try {
    const res = await fetch(
      'https://antaremas.com/wp-json/wp/v2/pages?slug=harga-emas',
      { signal: AbortSignal.timeout(10000), headers: wpApiHeaders }
    );

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

  // Attempt 2: WP REST API WITH www.
  try {
    const res = await fetch(
      'https://www.antaremas.com/wp-json/wp/v2/pages?slug=harga-emas',
      { signal: AbortSignal.timeout(10000), headers: wpApiHeaders }
    );

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

  // Attempt 3: Fetch the regular page
  try {
    const res = await fetch('https://antaremas.com/harga-emas/', {
      signal: AbortSignal.timeout(10000),
      headers: {
        ...wpApiHeaders,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
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

  debugLogs.push('antaremas: falling through to AI');

  // Fallback: Gemini 2.5 Flash + Google Search grounding (system + user prompt)
  const todayWIB = getTodayDateWIB();
  const userPrompt = `Cari harga emas Antam dari antaremas.com untuk HARI INI tanggal ${todayWIB}. HARUS harga tanggal ${todayWIB}, bukan tanggal lain.`;

  const searchResult = await callGeminiWithSearch(ANTAREMAS_SYSTEM_PROMPT, userPrompt);
  if (searchResult) {
    debugLogs.push(`antaremas_ai_search_raw: ${searchResult.substring(0, 200)}`);
    const result = validateGoldPrice(parseJsonFromAI(searchResult));
    if (result) return result;
  }

  // Fallback: AI chain without search
  const prompt = `${ANTAREMAS_SYSTEM_PROMPT}\n\nHari ini: ${todayWIB}`;

  for (const caller of [callGemini, callGroq, callOpenRouter]) {
    const text = await caller(prompt);
    if (text) {
      const result = validateGoldPrice(parseJsonFromAI(text));
      if (result) return result;
    }
  }

  return null;
}

async function fetchLogamMulia(): Promise<GoldPrice | null> {
  // Primary: Scrape harga-emas.org which shows LM Antam (= LogamMulia) prices
  try {
    const res = await fetch('https://harga-emas.org/', {
      signal: AbortSignal.timeout(10000),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Accept': 'text/html,*/*',
        'Accept-Language': 'id-ID,id;q=0.9',
      },
    });

    debugLogs.push(`hargaemas_status: ${res.status}`);

    if (res.ok) {
      const html = await res.text();
      debugLogs.push(`hargaemas_len: ${html.length}`);

      let buy = 0;
      let sell = 0;

      // buy_price: "Harga pembelian kembali: RpX.XXX.XXX/grm"
      const buybackMatch = html.match(
        /pembelian\s+kembali[^R]*Rp\s*([\d.,]+)/i
      );
      debugLogs.push(`hargaemas_buyback_match: ${buybackMatch ? buybackMatch[1] : 'null'}`);
      if (buybackMatch) {
        buy = parseInt(buybackMatch[1].replace(/[.,]/g, ''), 10);
      }

      // Debug: find context around "3.007" or the 1 gram row
      const idx1g = html.indexOf('>1<');
      debugLogs.push(`hargaemas_1g_idx: ${idx1g}`);
      if (idx1g >= 0) {
        debugLogs.push(`hargaemas_1g_ctx: ${html.substring(idx1g, idx1g + 200).replace(/\n/g, ' ')}`);
      }

      // Also search for the known price pattern (around 3.0XX.000)
      const priceIdx = html.search(/\d\.\d{3}\.\d{3}/);
      debugLogs.push(`hargaemas_price_idx: ${priceIdx}`);
      if (priceIdx >= 0) {
        debugLogs.push(`hargaemas_price_ctx: ${html.substring(Math.max(0, priceIdx - 50), priceIdx + 50).replace(/\n/g, ' ')}`);
      }

      // sell_price: LM Antam 1 gram row — try multiple patterns
      // HTML structure: >1</p></td><td class="GoldPriceTable..."><div...><p>3.007.000</p>
      const sellP1 = html.match(
        />\s*1\s*<\/p>\s*<\/td>\s*<td[^>]*>\s*<div[^>]*>\s*<p>\s*([\d.]{7,})\s*<\/p>/i
      );
      debugLogs.push(`hargaemas_sell_p1: ${sellP1 ? sellP1[1] : 'null'}`);

      // Pattern 2: standard table cells
      const sellP2 = html.match(
        /<td[^>]*>\s*1\s*<\/td>\s*<td[^>]*>\s*([\d.]{7,})\s*<\/td>/i
      );
      debugLogs.push(`hargaemas_sell_p2: ${sellP2 ? sellP2[1] : 'null'}`);

      // Pattern 3: loose match — >1< then within 200 chars find >X.XXX.XXX<
      const sellP3 = html.match(
        />\s*1\s*<[\s\S]{0,200}?>\s*(\d\.\d{3}\.\d{3})\s*</
      );
      debugLogs.push(`hargaemas_sell_p3: ${sellP3 ? sellP3[1] : 'null'}`);

      // Use first successful match
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

  // Fallback: Gemini with Google Search grounding
  const todayLM = getTodayDateWIB();
  const lmSystemPrompt = `Cari harga emas ANTAM Logam Mulia per 1 gram HARI INI (${todayLM}).
1. "buy" = Harga Buyback per gram (harga ANTAM beli kembali)
2. "sell" = Harga jual emas batangan 1 gram (harga pembeli bayar)
sell > buy. Integers dalam IDR. Harga wajar ~Rp 2-4 juta.
Return ONLY JSON: {"buy": <number>, "sell": <number>}`;
  const lmUserPrompt = `Cari harga emas ANTAM Logam Mulia untuk HARI INI tanggal ${todayLM} dari logammulia.com.`;

  const searchResult = await callGeminiWithSearch(lmSystemPrompt, lmUserPrompt);
  if (searchResult) {
    const result = validateGoldPrice(parseJsonFromAI(searchResult));
    if (result) return result;
  }

  // Fallback: AI chain
  const prompt = `You are a JSON-only data extractor. Based on your latest knowledge of logammulia.com (PT ANTAM Logam Mulia) gold prices today, extract:
- "buy" = harga buyback per gram (from the sell/buyback page)
- "sell" = harga jual emas batangan 1 gram (from the purchase page)

IMPORTANT: sell must be HIGHER than buy. Both are integers in IDR (e.g., 2500000).
Output ONLY valid JSON: {"buy": <number>, "sell": <number>}`;

  for (const caller of [callGemini, callGroq, callOpenRouter]) {
    const text = await caller(prompt);
    if (text) {
      const result = validateGoldPrice(parseJsonFromAI(text));
      if (result) return result;
    }
  }

  return null;
}

// ─────────────────────────────────────────────────────
// Main Handler
// ─────────────────────────────────────────────────────

Deno.serve(async (_req) => {
  // Reset debug logs for each request
  debugLogs.length = 0;
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch both sources in parallel
    const [antaremas, logamMulia] = await Promise.all([
      fetchAntaremas(),
      fetchLogamMulia(),
    ]);

    const results: { source: string; status: string; prices?: GoldPrice }[] = [];
    const url = new URL(_req.url);
    const debugMode = url.searchParams.get('debug') === '1';

    // INSERT antaremas price
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

    // INSERT logammulia price
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

    return new Response(JSON.stringify({ success: true, results, ...(debugMode ? { debug: debugLogs } : {}) }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
