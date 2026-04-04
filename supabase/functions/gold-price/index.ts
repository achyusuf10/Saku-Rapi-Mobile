/// Supabase Edge Function: gold-price
///
/// Cronjob (09:00 WIB / 02:00 UTC daily) untuk mengambil harga emas
/// dari antaremas.com dan logammulia.com → INSERT ke gold_prices.
///
/// Strategy:
/// - Thread 1 (Antaremas): WordPress REST API → Regex extract → AI Fallback
/// - Thread 2 (LogamMulia): Langsung AI Scraping Chain
/// - AI Fallback Chain: Gemini → Grok → OpenRouter

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY') ?? '';
const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const AI_TIMEOUT_MS = 15000;

interface GoldPrice {
  buy: number;
  sell: number;
}

// ─────────────────────────────────────────────────────
// AI Provider Helpers
// ─────────────────────────────────────────────────────

async function callGemini(prompt: string): Promise<string | null> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0 },
        }),
      }
    );
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();
    return data?.candidates?.[0]?.content?.parts?.[0]?.text ?? null;
  } catch {
    return null;
  }
}

async function callGroq(prompt: string): Promise<string | null> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);

    const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0,
      }),
    });
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();
    return data?.choices?.[0]?.message?.content ?? null;
  } catch {
    return null;
  }
}

async function callOpenRouter(prompt: string): Promise<string | null> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);

    const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'google/gemini-2.0-flash-001',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0,
      }),
    });
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();
    return data?.choices?.[0]?.message?.content ?? null;
  } catch {
    return null;
  }
}

function parseJsonFromAI(text: string): GoldPrice | null {
  try {
    const cleaned = text.replace(/```json\n?|```/g, '').trim();
    const parsed = JSON.parse(cleaned);
    if (typeof parsed.buy === 'number' && typeof parsed.sell === 'number') {
      return parsed as GoldPrice;
    }
    return null;
  } catch {
    return null;
  }
}

async function aiScrapeChain(url: string, sourceName: string): Promise<GoldPrice | null> {
  const prompt = `You are a JSON-only data extractor. Visit this URL content and extract gold prices.

URL: ${url}
Source: ${sourceName}

Find the current gold buyback/sell price per gram in Indonesian Rupiah (IDR).
For ${sourceName}:
- "buy" = harga beli (buyback) per gram
- "sell" = harga jual per gram

Output ONLY valid JSON with no extra text:
{"buy": <number>, "sell": <number>}

The prices should be integers in Rupiah (e.g., 1850000, not 1.85 million).`;

  // Try Gemini first
  const geminiResult = await callGemini(prompt);
  if (geminiResult) {
    const parsed = parseJsonFromAI(geminiResult);
    if (parsed) return parsed;
  }

  // Try Groq
  const groqResult = await callGroq(prompt);
  if (groqResult) {
    const parsed = parseJsonFromAI(groqResult);
    if (parsed) return parsed;
  }

  // Try OpenRouter
  const openRouterResult = await callOpenRouter(prompt);
  if (openRouterResult) {
    const parsed = parseJsonFromAI(openRouterResult);
    if (parsed) return parsed;
  }

  return null;
}

// ─────────────────────────────────────────────────────
// Source Fetchers
// ─────────────────────────────────────────────────────

async function fetchAntaremas(): Promise<GoldPrice | null> {
  try {
    // Try WordPress REST API first
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);

    const res = await fetch(
      'https://www.antaremas.com/wp-json/wp/v2/pages?slug=harga-emas-hari-ini&_fields=content',
      { signal: controller.signal }
    );
    clearTimeout(timeout);

    if (res.ok) {
      const data = await res.json();
      if (data?.[0]?.content?.rendered) {
        const html = data[0].content.rendered;

        // Regex: find "Buyback" price — format: Rp X.XXX.XXX
        const buybackRegex = /Buyback[^R]*Rp\s*([\d.]+)/i;
        const sellRegex = /Jual[^R]*Rp\s*([\d.]+)/i;

        const buyMatch = html.match(buybackRegex);
        const sellMatch = html.match(sellRegex);

        if (buyMatch && sellMatch) {
          const buy = parseInt(buyMatch[1].replace(/\./g, ''), 10);
          const sell = parseInt(sellMatch[1].replace(/\./g, ''), 10);
          if (buy > 0 && sell > 0) return { buy, sell };
        }
      }
    }
  } catch {
    // Fall through to AI
  }

  // Fallback to AI chain
  return aiScrapeChain('https://www.antaremas.com/harga-emas-hari-ini', 'antaremas.com');
}

async function fetchLogamMulia(): Promise<GoldPrice | null> {
  // LogamMulia doesn't have a clean API — go straight to AI chain
  return aiScrapeChain('https://www.logammulia.com/id/harga-emas-hari-ini', 'logammulia.com');
}

// ─────────────────────────────────────────────────────
// Main Handler
// ─────────────────────────────────────────────────────

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch both sources in parallel
    const [antaremas, logamMulia] = await Promise.all([
      fetchAntaremas(),
      fetchLogamMulia(),
    ]);

    const results: { source: string; status: string }[] = [];

    // INSERT antaremas price
    if (antaremas) {
      const { error } = await supabase.from('gold_prices').insert({
        source: 'antaremas',
        buy_price: antaremas.buy,
        sell_price: antaremas.sell,
      });
      results.push({
        source: 'antaremas',
        status: error ? `error: ${error.message}` : 'inserted',
      });
    } else {
      results.push({ source: 'antaremas', status: 'fetch_failed' });
    }

    // INSERT logammulia price
    if (logamMulia) {
      const { error } = await supabase.from('gold_prices').insert({
        source: 'logammulia',
        buy_price: logamMulia.buy,
        sell_price: logamMulia.sell,
      });
      results.push({
        source: 'logammulia',
        status: error ? `error: ${error.message}` : 'inserted',
      });
    } else {
      results.push({ source: 'logammulia', status: 'fetch_failed' });
    }

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
