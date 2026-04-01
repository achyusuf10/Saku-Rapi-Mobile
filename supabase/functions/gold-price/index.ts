/// Supabase Edge Function: gold-price
///
/// Mengambil harga buyback Emas Antam per 1 gram,
/// dilengkapi cache 24 jam di tabel `gold_prices_cache`.
///
/// Flow:
/// 1. Cek cache (gold_prices_cache) — jika < 24 jam → return langsung
/// 2. Direct scrape via WordPress REST API (< 1 detik, tanpa AI)
/// 3. Gemini + Google Search ke GOLD_PRICE_URL (antaremas.com)
/// 4. Gemini + Google Search ke DEFAULT_GOLD_URL (logammulia.com)
/// 5. Fetch page → Groq → OpenRouter
///
/// Environment variables:
/// - GOLD_PRICE_URL: URL utama (antaremas.com/harga-emas/)
/// - GEMINI_API_KEY, GROQ_API_KEY, OPENROUTER_API_KEY

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

// ─────────────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────────────

const DEFAULT_GOLD_URL = 'https://www.logammulia.com/id/harga-emas-hari-ini';
const GEMINI_TIMEOUT_MS = 12_000;
const GROQ_TIMEOUT_MS = 10_000;
const OPENROUTER_TIMEOUT_MS = 12_000;
const FETCH_URL_TIMEOUT_MS = 10_000;
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 jam

/// Max karakter page content yang dikirim ke Groq/OpenRouter (hemat token).
const MAX_PAGE_CONTENT_LENGTH = 4_000;

// ─────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────

/// Return tanggal hari ini dalam format `yyyy-MM-dd` (zona WIB / UTC+7).
function getTodayDateWIB(): string {
  const now = new Date();
  const wib = new Date(now.getTime() + 7 * 60 * 60 * 1000);
  return wib.toISOString().split('T')[0];
}

/// Cek apakah cache masih fresh (< 24 jam dari sekarang).
function isCacheFresh(createdAt: string): boolean {
  const cacheTime = new Date(createdAt).getTime();
  return Date.now() - cacheTime < CACHE_TTL_MS;
}

// ─────────────────────────────────────────────────────
// Prompts
// ─────────────────────────────────────────────────────

/// System prompt — ringkas, langsung ke inti.
const GOLD_SYSTEM_PROMPT = `Cari harga BUYBACK Emas Antam per 1 gram HARI INI dalam Rupiah (IDR).
Buyback = harga beli kembali oleh Antam, BUKAN harga jual.

Cara menemukan harga:
- Di antaremas.com: cari tabel "TABEL HARGA BUYBACK" → baris "Buyback per 1 Gr" → ambil harganya.
- Di logammulia.com: cari bagian "Harga Buyback" → harga per gram.

PENTING:
- Pastikan tanggal di halaman SAMA dengan tanggal yang diminta. Jika tanggal berbeda, set confidence = "low".
- Ambil harga yang paling terbaru/terkini, BUKAN harga kemarin atau tanggal lama.

Return ONLY JSON (tanpa markdown/penjelasan):
{"price_per_gram_idr":<angka tanpa titik pemisah>,"source_description":"<sumber>","confidence":"high|low"}

Contoh: "Rp. 2.742.000" → {"price_per_gram_idr":2742000,"source_description":"antaremas.com","confidence":"high"}
Jika tidak ketemu atau tanggal tidak cocok: {"price_per_gram_idr":null,"source_description":null,"confidence":"low"}`;

/// User prompt untuk Gemini (search grounding).
function buildGeminiUserPrompt(targetUrl: string): string {
  const today = getTodayDateWIB();
  return `Cari harga buyback Emas Antam per 1 gram untuk HARI INI tanggal ${today}. HARUS harga tanggal ${today}, bukan tanggal lain. Sumber: ${targetUrl}`;
}

/// User prompt untuk Groq/OpenRouter (dengan page content).
function buildFallbackUserPrompt(pageContent: string): string {
  const today = getTodayDateWIB();
  return `Cari harga "Buyback per 1 Gr" atau "Harga Buyback" per 1 gram untuk tanggal ${today} dari halaman berikut. Pastikan tanggal di halaman cocok dengan ${today}:\n\n${pageContent.substring(0, MAX_PAGE_CONTENT_LENGTH)}`;
}

// ─────────────────────────────────────────────────────
// HTML → text stripper (optimized: extract body, strip nav/header/footer)
// ─────────────────────────────────────────────────────

function stripHtml(html: string): string {
  // 1. Coba ekstrak isi <body> saja
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  let text = bodyMatch ? bodyMatch[1] : html;

  // 2. Hapus blok non-konten: header, nav, footer, script, style, noscript
  text = text.replace(/<header[\s\S]*?<\/header>/gi, ' ');
  text = text.replace(/<nav[\s\S]*?<\/nav>/gi, ' ');
  text = text.replace(/<footer[\s\S]*?<\/footer>/gi, ' ');
  text = text.replace(/<script[\s\S]*?<\/script>/gi, ' ');
  text = text.replace(/<style[\s\S]*?<\/style>/gi, ' ');
  text = text.replace(/<noscript[\s\S]*?<\/noscript>/gi, ' ');

  // 3. Hapus sisa tag HTML
  text = text.replace(/<[^>]+>/g, ' ');

  // 4. Decode HTML entities
  text = text.replace(/&nbsp;/g, ' ');
  text = text.replace(/&amp;/g, '&');
  text = text.replace(/&lt;/g, '<');
  text = text.replace(/&gt;/g, '>');
  text = text.replace(/&quot;/g, '"');
  text = text.replace(/&#\d+;/g, ' ');

  // 5. Collapse whitespace
  text = text.replace(/\s+/g, ' ').trim();
  return text;
}

// ─────────────────────────────────────────────────────
// JSON sanitizer
// ─────────────────────────────────────────────────────

function sanitizeJson(raw: string): string {
  let cleaned = raw.trim();
  // Remove markdown code fences
  cleaned = cleaned.replace(/^```(?:json)?\s*\n?/i, '');
  cleaned = cleaned.replace(/\n?```\s*$/i, '');
  // Try to extract JSON object if surrounded by text
  const match = cleaned.match(/\{[\s\S]*\}/);
  if (match) cleaned = match[0];
  return cleaned.trim();
}

// ─────────────────────────────────────────────────────
// AI Provider calls
// ─────────────────────────────────────────────────────

/// Gemini with Google Search grounding + systemInstruction.
async function callGeminiWithSearch(
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const apiKey = Deno.env.get('GEMINI_API_KEY') ?? '';
  if (!apiKey) throw new Error('GEMINI_API_KEY not set');

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemPrompt }] },
          contents: [{ parts: [{ text: userPrompt }] }],
          tools: [{ google_search: {} }],
          generationConfig: {
            temperature: 0.1,
          },
        }),
      },
    );

    if (!res.ok) {
      const errText = await res.text().catch(() => 'unknown');
      throw new Error(`Gemini HTTP ${res.status}: ${errText}`);
    }

    const json = await res.json();
    const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    console.log('[gold-price] Gemini raw response:', rawText.substring(0, 300));
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'gemini' };
  } finally {
    clearTimeout(timeout);
  }
}

/// Groq — system/user prompt split + response_format json_object.
async function callGroq(
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const apiKey = Deno.env.get('GROQ_API_KEY') ?? '';
  if (!apiKey) throw new Error('GROQ_API_KEY not set');

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GROQ_TIMEOUT_MS);

  try {
    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
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
      const errText = await res.text().catch(() => 'unknown');
      throw new Error(`Groq HTTP ${res.status}: ${errText}`);
    }

    const json = await res.json();
    const rawText = json?.choices?.[0]?.message?.content ?? '';
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'groq' };
  } finally {
    clearTimeout(timeout);
  }
}

/// OpenRouter — system/user prompt split.
async function callOpenRouter(
  systemPrompt: string,
  userPrompt: string,
): Promise<{ data: unknown; provider: string }> {
  const apiKey = Deno.env.get('OPENROUTER_API_KEY') ?? '';
  if (!apiKey) throw new Error('OPENROUTER_API_KEY not set');

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENROUTER_TIMEOUT_MS);

  try {
    const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'google/gemma-3-27b-it:free',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.1,
      }),
    });

    if (!res.ok) {
      const errText = await res.text().catch(() => 'unknown');
      throw new Error(`OpenRouter HTTP ${res.status}: ${errText}`);
    }

    const json = await res.json();
    const rawText = json?.choices?.[0]?.message?.content ?? '';
    return { data: JSON.parse(sanitizeJson(rawText)), provider: 'openrouter' };
  } finally {
    clearTimeout(timeout);
  }
}

// ─────────────────────────────────────────────────────
// WordPress REST API direct scrape (NO AI needed)
// ─────────────────────────────────────────────────────

/// Map nama bulan Indonesia → angka.
function monthToNum(month: string): string {
  const months: Record<string, string> = {
    'januari': '01', 'februari': '02', 'maret': '03', 'april': '04',
    'mei': '05', 'juni': '06', 'juli': '07', 'agustus': '08',
    'september': '09', 'oktober': '10', 'november': '11', 'desember': '12',
  };
  return months[month.toLowerCase()] ?? '00';
}

/// Coba ambil harga buyback langsung dari WordPress REST API.
/// Jauh lebih cepat (< 1 detik) dan akurat karena parse HTML langsung.
async function tryDirectScrape(pageUrl: string): Promise<{
  price: number;
  pageDate: string;
  source: string;
} | null> {
  try {
    // Konversi URL halaman ke WP REST API endpoint
    const wpApiUrl = pageUrl.replace(/\/harga-emas\/?$/, '/wp-json/wp/v2/pages?slug=harga-emas');
    console.log('[gold-price] WP API URL:', wpApiUrl);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), FETCH_URL_TIMEOUT_MS);

    try {
      const res = await fetch(wpApiUrl, {
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        },
        signal: controller.signal,
      });

      if (!res.ok) {
        console.log('[gold-price] WP API HTTP', res.status);
        return null;
      }

      const pages = await res.json();
      if (!Array.isArray(pages) || pages.length === 0) {
        console.log('[gold-price] WP API returned empty array');
        return null;
      }

      const html: string = pages[0]?.content?.rendered ?? '';
      if (!html) {
        console.log('[gold-price] WP API content.rendered is empty');
        return null;
      }

      // Cari harga buyback: <td>Buyback per 1 Gr</td><td>Rp. 2.742.000</td>
      const buybackMatch = html.match(
        /Buyback\s+per\s+1\s+Gr<\/td>\s*<td[^>]*>Rp\.\s*([\d.]+)/i,
      );

      if (!buybackMatch) {
        console.log('[gold-price] WP API: buyback pattern not found in HTML');
        return null;
      }

      // Parse harga: "2.742.000" → 2742000
      const priceStr = buybackMatch[1].replace(/\./g, '');
      const price = parseInt(priceStr, 10);

      if (isNaN(price) || price <= 0) {
        console.log('[gold-price] WP API: invalid price:', priceStr);
        return null;
      }

      // Ambil tanggal dari heading halaman, misal "31 Maret 2026"
      const dateMatch = html.match(
        /(\d{1,2})\s+(Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember)\s+(\d{4})/i,
      );

      const pageDate = dateMatch
        ? `${dateMatch[3]}-${monthToNum(dateMatch[2])}-${dateMatch[1].padStart(2, '0')}`
        : '';

      console.log('[gold-price] WP API scraped: price=', price, 'date=', pageDate);
      return { price, pageDate, source: 'antaremas.com (direct scrape)' };
    } finally {
      clearTimeout(timeout);
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.log('[gold-price] WP API scrape error:', msg);
    return null;
  }
}

/// Ambil konten halaman dari WP REST API (lebih bersih, tanpa nav/header/footer).
async function fetchWpApiContent(pageUrl: string): Promise<string | null> {
  try {
    const wpApiUrl = pageUrl.replace(/\/harga-emas\/?$/, '/wp-json/wp/v2/pages?slug=harga-emas');

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), FETCH_URL_TIMEOUT_MS);

    try {
      const res = await fetch(wpApiUrl, {
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        },
        signal: controller.signal,
      });

      if (!res.ok) return null;

      const pages = await res.json();
      if (!Array.isArray(pages) || pages.length === 0) return null;

      const html: string = pages[0]?.content?.rendered ?? '';
      if (!html) return null;

      // Strip HTML tags dari content.rendered (sudah bersih, tanpa nav/header/footer)
      const stripped = stripHtml(html);
      return stripped.length >= 50 ? stripped : null;
    } finally {
      clearTimeout(timeout);
    }
  } catch {
    return null;
  }
}

// ─────────────────────────────────────────────────────
// Fetch target URL content (fallback untuk non-WordPress sites)
// ─────────────────────────────────────────────────────

async function fetchPageContent(url: string): Promise<string | null> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_URL_TIMEOUT_MS);

  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
      signal: controller.signal,
      redirect: 'follow',
    });

    if (!res.ok) return null;
    const html = await res.text();
    const stripped = stripHtml(html);
    return stripped.length >= 50 ? stripped : null;
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

// ─────────────────────────────────────────────────────
// Validation helper
// ─────────────────────────────────────────────────────

/// Cek apakah result AI valid (ada price > 0).
function isValidResult(data: unknown): boolean {
  if (!data || typeof data !== 'object') return false;
  const d = data as Record<string, unknown>;
  return typeof d.price_per_gram_idr === 'number' && d.price_per_gram_idr > 0;
}

// ─────────────────────────────────────────────────────
// Main handler
// ─────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('[gold-price] Request received:', req.method);

    // ── JWT Validation ──
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ success: false, error: 'Missing authorization header' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      console.log('[gold-price] Auth failed:', authError?.message ?? 'no user');
      return jsonResponse({ success: false, error: 'Unauthorized' }, 401);
    }

    console.log('[gold-price] Auth OK, user:', user.id);

    // ══════════════════════════════════════════════════
    // Step 1: Cek cache — TTL 24 jam
    // ══════════════════════════════════════════════════
    const todayDate = getTodayDateWIB();
    console.log('[gold-price] Checking cache for date:', todayDate);

    const { data: cached } = await supabase
      .from('gold_prices_cache')
      .select('price_per_gram_idr, provider, source, created_at')
      .eq('date', todayDate)
      .maybeSingle();

    if (cached && cached.price_per_gram_idr > 0 && isCacheFresh(cached.created_at)) {
      console.log('[gold-price] Cache HIT (TTL OK):', cached.price_per_gram_idr);
      return jsonResponse({
        success: true,
        price_per_gram_idr: cached.price_per_gram_idr,
        provider: cached.provider ?? 'cache',
        source: cached.source ?? 'gold_prices_cache',
        confidence: 'high',
        cached: true,
      });
    }

    if (cached) {
      console.log('[gold-price] Cache EXPIRED — refetching');
    } else {
      console.log('[gold-price] Cache MISS — calling AI providers');
    }

    // ── Tentukan URLs ──
    const primaryUrl = Deno.env.get('GOLD_PRICE_URL') ?? 'https://antaremas.com/harga-emas/';
    const fallbackUrl = DEFAULT_GOLD_URL;

    console.log('[gold-price] Primary URL:', primaryUrl, '| Fallback URL:', fallbackUrl);

    let result: { data: unknown; provider: string } | null = null;
    const errors: Record<string, string> = {};

    // ══════════════════════════════════════════════════
    // Step 2: Direct scrape via WordPress REST API (< 1 detik)
    // ══════════════════════════════════════════════════
    try {
      console.log('[gold-price] Step 2: WP REST API direct scrape');
      const scraped = await tryDirectScrape(primaryUrl);

      if (scraped) {
        // Verifikasi tanggal halaman = hari ini
        if (scraped.pageDate === todayDate) {
          console.log('[gold-price] Step 2 OK — direct scrape matched today:', scraped.price);
          result = {
            data: {
              price_per_gram_idr: scraped.price,
              source_description: scraped.source,
              confidence: 'high',
            },
            provider: 'direct_scrape',
          };
        } else {
          console.log('[gold-price] Step 2: date mismatch — page:', scraped.pageDate, 'vs today:', todayDate);
          errors['direct_scrape'] = `Date mismatch: page=${scraped.pageDate}, today=${todayDate}`;
        }
      } else {
        errors['direct_scrape'] = 'Scrape returned null (pattern not found or API unreachable)';
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      errors['direct_scrape'] = msg;
      console.error('[gold-price] Step 2 failed:', msg);
    }

    // ══════════════════════════════════════════════════
    // Step 3: Gemini + Google Search → Primary URL (antaremas.com)
    // ══════════════════════════════════════════════════
    if (!result || !isValidResult(result.data)) {
      try {
        console.log('[gold-price] Step 3: Gemini → primary URL');
        const userPrompt = buildGeminiUserPrompt(primaryUrl);
        result = await callGeminiWithSearch(GOLD_SYSTEM_PROMPT, userPrompt);
        console.log('[gold-price] Step 3 OK');
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        errors['gemini_primary'] = msg;
        console.error('[gold-price] Step 3 failed:', msg);
      }
    }

    // ══════════════════════════════════════════════════
    // Step 4: Gemini + Google Search → Fallback URL (logammulia.com)
    // ══════════════════════════════════════════════════
    if (!result || !isValidResult(result.data)) {
      try {
        console.log('[gold-price] Step 4: Gemini → fallback URL');
        const userPrompt = buildGeminiUserPrompt(fallbackUrl);
        result = await callGeminiWithSearch(GOLD_SYSTEM_PROMPT, userPrompt);
        console.log('[gold-price] Step 4 OK');
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        errors['gemini_fallback'] = msg;
        console.error('[gold-price] Step 4 failed:', msg);
      }
    }

    // ══════════════════════════════════════════════════
    // Step 5: Fetch page content → Groq → OpenRouter
    // ══════════════════════════════════════════════════
    if (!result || !isValidResult(result.data)) {
      console.log('[gold-price] Step 5: Fetch page + Groq/OpenRouter');

      // Prioritas: WP REST API content (bersih) > full page fetch
      const pageContent = await fetchWpApiContent(primaryUrl)
        ?? await fetchPageContent(fallbackUrl)
        ?? await fetchPageContent(primaryUrl);

      const userPrompt = pageContent
        ? (console.log('[gold-price] Page content obtained, length:', pageContent.length),
           buildFallbackUserPrompt(pageContent))
        : (console.log('[gold-price] All page fetches failed, using general prompt'),
           `Harga buyback Emas Antam per 1 gram hari ini (${getTodayDateWIB()}) dalam IDR?`);

      try {
        result = await callGroq(GOLD_SYSTEM_PROMPT, userPrompt);
        console.log('[gold-price] Groq OK');
      } catch (groqErr: unknown) {
        const groqMsg = groqErr instanceof Error ? groqErr.message : String(groqErr);
        errors['groq'] = groqMsg;
        console.error('[gold-price] Groq failed:', groqMsg);
        try {
          result = await callOpenRouter(GOLD_SYSTEM_PROMPT, userPrompt);
          console.log('[gold-price] OpenRouter OK');
        } catch (openrouterErr: unknown) {
          const orMsg = openrouterErr instanceof Error ? openrouterErr.message : String(openrouterErr);
          errors['openrouter'] = orMsg;
          console.error('[gold-price] OpenRouter failed:', orMsg);
        }
      }
    }

    // ── Final check ──
    if (!result || !isValidResult(result.data)) {
      return jsonResponse({
        success: false,
        error: 'AI_BUSY',
        detail: 'All providers failed to extract gold price',
        provider_errors: errors,
        raw_result: result?.data ?? null,
      }, 503);
    }

    const aiResult = result.data as Record<string, unknown>;
    const pricePerGram = aiResult.price_per_gram_idr as number;

    // ══════════════════════════════════════════════════
    // Step 6: Upsert ke cache (TTL 24 jam — reset created_at)
    // ══════════════════════════════════════════════════
    const { error: upsertError } = await supabase
      .from('gold_prices_cache')
      .upsert(
        {
          date: todayDate,
          price_per_gram_idr: pricePerGram,
          provider: result.provider,
          source: (aiResult.source_description as string) ?? null,
          created_at: new Date().toISOString(),
        },
        { onConflict: 'date' },
      );

    if (upsertError) {
      console.error('[gold-price] Cache upsert failed:', upsertError.message);
    } else {
      console.log('[gold-price] Cache stored for', todayDate, '(TTL 24h)');
    }

    console.log('[gold-price] Success:', pricePerGram, 'via', result.provider);
    return jsonResponse({
      success: true,
      price_per_gram_idr: pricePerGram,
      provider: result.provider,
      source: aiResult.source_description ?? null,
      confidence: aiResult.confidence ?? 'unknown',
      cached: false,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error('[gold-price] Unhandled error:', msg);
    return jsonResponse({ success: false, error: `Internal server error: ${msg}` }, 500);
  }
});
