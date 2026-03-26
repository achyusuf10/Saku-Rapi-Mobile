/// Supabase Edge Function: gold-price
///
/// Mengambil harga emas terkini menggunakan AI:
/// - Gemini (primary): Google Search grounding — AI cari sendiri harga emas terbaru
/// - Groq/OpenRouter (fallback): fetch HTML page → kirim ke AI
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
const GEMINI_TIMEOUT_MS = 15000;
const GROQ_TIMEOUT_MS = 10000;
const OPENROUTER_TIMEOUT_MS = 12000;
const FETCH_URL_TIMEOUT_MS = 15000;

// ─────────────────────────────────────────────────────
// Prompts
// ─────────────────────────────────────────────────────

/// Prompt untuk Gemini (dengan Google Search grounding, tanpa perlu page content).
function buildSearchPrompt(targetUrl: string): string {
  return `You are a gold price extractor. Find the CURRENT buyback gold price per gram in Indonesian Rupiah (IDR) today.

You can reference this URL for the source: ${targetUrl}

Return a JSON object with these exact fields:
{
  "price_per_gram_idr": <number — gold price per gram in IDR, no thousand separators>,
  "source_description": "<where the price was found>",
  "confidence": "<high or low>"
}

Rules:
- Find the CURRENT, LATEST buyback gold price per gram in IDR.
- Prefer the SELL price for 24 karat gold per gram.
- Convert formatted numbers (e.g., "1.850.000") to plain number (1850000).
- If you cannot find it, return {"price_per_gram_idr": null, "source_description": null, "confidence": "low"}.

Return ONLY the JSON object, no explanation or markdown.`;
}

/// Prompt untuk Groq/OpenRouter (dengan page content).
function buildPageContentPrompt(pageContent: string): string {
  return `You are a gold price extractor. From the following webpage content, extract the current buyback gold price per gram in Indonesian Rupiah (IDR).

Return a JSON object with these exact fields:
{
  "price_per_gram_idr": <number — gold price per gram in IDR, without thousand separators>,
  "source_description": "<brief description of where the price was found>",
  "confidence": "<high or low>"
}

Rules:
- Look for buyback gold price per gram in IDR (Rupiah). Common patterns: "Rp", "IDR", "/gram".
- If multiple prices exist (buy/sell/24k/etc), prefer the SELL price for 24 karat gold per gram.
- Convert any formatted number (e.g., "1.850.000" or "1,850,000") to a plain number (1850000).
- If you cannot find a buyback gold price in IDR, return {"price_per_gram_idr": null, "source_description": null, "confidence": "low"}.

Webpage content:
${pageContent.substring(0, 8000)}

Return ONLY the JSON object, no explanation or markdown.`;
}

// ─────────────────────────────────────────────────────
// HTML → text stripper
// ─────────────────────────────────────────────────────

function stripHtml(html: string): string {
  let text = html.replace(/<script[\s\S]*?<\/script>/gi, ' ');
  text = text.replace(/<style[\s\S]*?<\/style>/gi, ' ');
  text = text.replace(/<[^>]+>/g, ' ');
  text = text.replace(/&nbsp;/g, ' ');
  text = text.replace(/&amp;/g, '&');
  text = text.replace(/&lt;/g, '<');
  text = text.replace(/&gt;/g, '>');
  text = text.replace(/&quot;/g, '"');
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

/// Gemini with Google Search grounding — AI searches the web itself.
async function callGeminiWithSearch(prompt: string): Promise<{ data: unknown; provider: string }> {
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
          contents: [{ parts: [{ text: prompt }] }],
          tools: [{ google_search: {} }],
          generationConfig: { temperature: 0.1 },
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

async function callGroq(prompt: string): Promise<{ data: unknown; provider: string }> {
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
        messages: [{ role: 'user', content: prompt }],
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

async function callOpenRouter(prompt: string): Promise<{ data: unknown; provider: string }> {
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
        messages: [{ role: 'user', content: prompt }],
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
    // Strategy 1: Gemini + Google Search grounding
    //   → AI langsung cari di web, tidak perlu fetch URL
    // ══════════════════════════════════════════════════
    let result: { data: unknown; provider: string } | null = null;

    try {
      const searchPrompt = buildSearchPrompt(targetUrl);
      result = await callGeminiWithSearch(searchPrompt);
      console.log('[gold-price] Gemini+Search OK');
    } catch (geminiErr: unknown) {
      console.error('[gold-price] Gemini+Search failed:', geminiErr);
    }

    // ══════════════════════════════════════════════════
    // Strategy 2: Fetch page → Groq / OpenRouter
    //   → Fallback, ambil HTML dan kirim text ke AI
    // ══════════════════════════════════════════════════
    if (!result || !isValidResult(result.data)) {
      console.log('[gold-price] Trying fallback: fetch page + Groq/OpenRouter');

      const pageContent = await fetchPageContent(targetUrl);
      if (pageContent) {
        console.log('[gold-price] Page fetched, length:', pageContent.length);
        const contentPrompt = buildPageContentPrompt(pageContent);

        try {
          result = await callGroq(contentPrompt);
          console.log('[gold-price] Groq OK');
        } catch (groqErr: unknown) {
          console.error('[gold-price] Groq failed:', groqErr);
          try {
            result = await callOpenRouter(contentPrompt);
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

    console.log('[gold-price] Success:', pricePerGram, 'via', result.provider);
    return jsonResponse({
      success: true,
      price_per_gram_idr: pricePerGram,
      provider: result.provider,
      source: aiResult.source_description ?? null,
      confidence: aiResult.confidence ?? 'unknown',
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error('[gold-price] Unhandled error:', msg);
    return jsonResponse({ success: false, error: `Internal server error: ${msg}` }, 500);
  }
});

/// Cek apakah result AI valid (ada price > 0).
function isValidResult(data: unknown): boolean {
  if (!data || typeof data !== 'object') return false;
  const d = data as Record<string, unknown>;
  return typeof d.price_per_gram_idr === 'number' && d.price_per_gram_idr > 0;
}
