/// Supabase Edge Function: gold-price
///
/// Mengambil harga emas Antam (Logam Mulia) terkini menggunakan AI,
/// dilengkapi 1-Day On-Demand Cache di tabel `gold_prices_cache`.
///
/// Flow:
/// 1. Cek cache Supabase (gold_prices_cache) — jika hari ini sudah ada → return langsung
/// 2. Gemini (primary): Google Search grounding + systemInstruction
/// 3. Groq/OpenRouter (fallback): fetch HTML page → optimize → kirim ke AI
/// 4. Setelah AI berhasil → upsert ke cache
///
/// Environment variables:
/// - GOLD_PRICE_URL: URL target untuk fallback scrape (opsional)
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
const GEMINI_TIMEOUT_MS = 8_000;
const GROQ_TIMEOUT_MS = 10_000;
const OPENROUTER_TIMEOUT_MS = 12_000;
const FETCH_URL_TIMEOUT_MS = 10_000;

/// Max karakter page content yang dikirim ke Groq/OpenRouter (hemat token).
const MAX_PAGE_CONTENT_LENGTH = 4_000;

// ─────────────────────────────────────────────────────
// Helpers: tanggal hari ini WIB (UTC+7)
// ─────────────────────────────────────────────────────

/// Return tanggal hari ini dalam format `yyyy-MM-dd` (zona WIB / UTC+7).
function getTodayDateWIB(): string {
  const now = new Date();
  const wib = new Date(now.getTime() + 7 * 60 * 60 * 1000);
  return wib.toISOString().split('T')[0];
}

// ─────────────────────────────────────────────────────
// Prompts — System + User dipisah
// ─────────────────────────────────────────────────────

/// System prompt (shared rules + JSON template) — dipakai oleh semua provider.
const GOLD_SYSTEM_PROMPT = `You are a gold price extractor specializing in Indonesian gold market data.
Your ONLY task is to find the CURRENT DAILY price for "Emas Antam" (produced by PT Aneka Tambang / Logam Mulia).

IMPORTANT DISTINCTIONS:
- You MUST find the BUYBACK price (harga beli kembali / buyback Antam), NOT the selling price.
- "Emas Antam" is a specific Indonesian gold product, NOT the global XAU/USD spot price.
- The buyback price is the price at which Antam will repurchase 1 gram of their certified gold bar.
- Common source: logammulia.com, harga-emas.org, or major Indonesian financial news.

OUTPUT — return a JSON object with exactly these fields:
{
  "price_per_gram_idr": <number — Antam buyback price per gram in IDR, plain number without thousand separators>,
  "source_description": "<brief description of the source>",
  "confidence": "<high or low>"
}

RULES:
1. Find TODAY's Antam buyback price per gram in IDR.
2. Convert formatted numbers (e.g., "1.850.000" or "Rp1.850.000") to plain number (1850000).
3. If you cannot find the Antam buyback price, return {"price_per_gram_idr": null, "source_description": null, "confidence": "low"}.
4. Return ONLY the JSON object, no explanation or markdown.`;

/// User prompt untuk Gemini (search grounding — AI cari sendiri).
function buildGeminiUserPrompt(targetUrl: string): string {
  const today = getTodayDateWIB();
  return `Find today's (${today}) Emas Antam buyback price per gram in IDR. You may reference: ${targetUrl}`;
}

/// User prompt untuk Groq/OpenRouter (dengan page content).
function buildFallbackUserPrompt(pageContent: string): string {
  const today = getTodayDateWIB();
  return `Extract today's (${today}) Emas Antam buyback price per gram in IDR from this webpage content:\n\n${pageContent.substring(0, MAX_PAGE_CONTENT_LENGTH)}`;
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
            responseMimeType: 'application/json',
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
// Fetch target URL content (hanya untuk fallback Groq/OpenRouter)
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
    // Step 1: Cek cache 1-day di gold_prices_cache
    // ══════════════════════════════════════════════════
    const todayDate = getTodayDateWIB();
    console.log('[gold-price] Checking cache for date:', todayDate);

    const { data: cached } = await supabase
      .from('gold_prices_cache')
      .select('price_per_gram_idr, provider, source')
      .eq('date', todayDate)
      .maybeSingle();

    if (cached && cached.price_per_gram_idr > 0) {
      console.log('[gold-price] Cache HIT:', cached.price_per_gram_idr);
      return jsonResponse({
        success: true,
        price_per_gram_idr: cached.price_per_gram_idr,
        provider: cached.provider ?? 'cache',
        source: cached.source ?? 'gold_prices_cache',
        confidence: 'high',
        cached: true,
      });
    }

    console.log('[gold-price] Cache MISS — calling AI providers');

    // ── Tentukan URL target ──
    let body: Record<string, unknown> = {};
    try {
      body = await req.json();
    } catch {
      // Body kosong — OK
    }

    const envUrl = Deno.env.get('GOLD_PRICE_URL') ?? '';
    const targetUrl: string = (body.url as string) || envUrl || DEFAULT_GOLD_URL;

    console.log('[gold-price] Target URL:', targetUrl);

    // ══════════════════════════════════════════════════
    // Step 2: Gemini + Google Search grounding
    //   → AI langsung cari di web, tidak perlu fetch URL
    // ══════════════════════════════════════════════════
    let result: { data: unknown; provider: string } | null = null;

    try {
      const userPrompt = buildGeminiUserPrompt(targetUrl);
      result = await callGeminiWithSearch(GOLD_SYSTEM_PROMPT, userPrompt);
      console.log('[gold-price] Gemini+Search OK');
    } catch (geminiErr: unknown) {
      console.error('[gold-price] Gemini+Search failed:', geminiErr);
    }

    // ══════════════════════════════════════════════════
    // Step 3: Fallback → Fetch page → Groq / OpenRouter
    //   → Ambil HTML, strip & optimize, kirim ke AI
    // ══════════════════════════════════════════════════
    if (!result || !isValidResult(result.data)) {
      console.log('[gold-price] Trying fallback: fetch page + Groq/OpenRouter');

      const pageContent = await fetchPageContent(targetUrl);
      if (pageContent) {
        console.log('[gold-price] Page fetched, length:', pageContent.length);
        const userPrompt = buildFallbackUserPrompt(pageContent);

        try {
          result = await callGroq(GOLD_SYSTEM_PROMPT, userPrompt);
          console.log('[gold-price] Groq OK');
        } catch (groqErr: unknown) {
          console.error('[gold-price] Groq failed:', groqErr);
          try {
            result = await callOpenRouter(GOLD_SYSTEM_PROMPT, userPrompt);
            console.log('[gold-price] OpenRouter OK');
          } catch (openrouterErr: unknown) {
            console.error('[gold-price] OpenRouter failed:', openrouterErr);
          }
        }
      } else {
        console.log('[gold-price] Page fetch failed, skipping Groq/OpenRouter');
      }
    }

    // ── Final check ──
    if (!result) {
      return jsonResponse({ success: false, error: 'AI_BUSY' }, 503);
    }

    const aiResult = result.data as Record<string, unknown>;
    const pricePerGram = aiResult?.price_per_gram_idr;

    if (pricePerGram == null || typeof pricePerGram !== 'number' || pricePerGram <= 0) {
      return jsonResponse(
        {
          success: false,
          error: 'AI could not extract gold price',
          provider: result.provider,
          raw: aiResult,
        },
        422,
      );
    }

    // ══════════════════════════════════════════════════
    // Step 4: Upsert ke cache gold_prices_cache
    // ══════════════════════════════════════════════════
    const { error: upsertError } = await supabase
      .from('gold_prices_cache')
      .upsert(
        {
          date: todayDate,
          price_per_gram_idr: pricePerGram,
          provider: result.provider,
          source: (aiResult.source_description as string) ?? null,
        },
        { onConflict: 'date' },
      );

    if (upsertError) {
      console.error('[gold-price] Cache upsert failed:', upsertError.message);
      // Non-blocking — tetap return response meskipun cache gagal
    } else {
      console.log('[gold-price] Cache stored for', todayDate);
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
