/// Supabase Edge Function: ai-parse
///
/// Menerima teks voice/OCR dan mengembalikan hasil parsing
/// terstruktur dari AI (Gemini → Groq → OpenRouter failover).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY') ?? '';
const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

const GEMINI_TIMEOUT_MS = 8000;
const GROQ_TIMEOUT_MS = 6000;
const OPENROUTER_TIMEOUT_MS = 10000;

// ─────────────────────────────────────────────────────
// Prompt builders
// ─────────────────────────────────────────────────────

function buildVoicePrompt(text: string): string {
  return `You are a financial transaction parser. Extract transaction information from the following voice input text (in Indonesian/English).

Return a JSON object with these exact fields:
{
  "amount": <number or null>,
  "categoryKeyword": "<single lowercase keyword for category, e.g. makan, transportasi, belanja, gaji>",
  "note": "<remaining descriptive text or null>",
  "type": "<expense or income>"
}

Rules:
- Default type is "expense". Use "income" only if words like "gaji", "terima", "dapat", "masuk", "bonus" appear.
- Extract the monetary amount. Convert shorthand like "25rb" to 25000, "1.5jt" to 1500000.
- categoryKeyword should be a single word describing the spending/income category.
- note should contain remaining context not captured by other fields.

Voice input: "${text}"

Return ONLY the JSON object, no explanation or markdown.`;
}

function buildOcrPromptForImage(): string {
  return `You are a receipt/invoice parser. Analyze the receipt/invoice image and extract structured data.

Return a JSON object with these exact fields:
{
  "merchantName": "<store/merchant name or null>",
  "date": "<transaction date in yyyy-MM-dd format or null>",
  "grandTotal": <total amount paid as number or null>,
  "items": [
    { "name": "<item name>", "qty": <quantity as number, default 1>, "unitPrice": <price per unit as number or null>, "subtotal": <total price for this line item as number> }
  ]
}

Rules:
- Extract the merchant name (usually at the top of the receipt).
- Extract the date in yyyy-MM-dd format.
- grandTotal is the final total amount paid (after tax/discount if applicable).
- items are individual line items with their prices.
- For each item, extract quantity if available (default to 1).
- unitPrice is the price per single unit. subtotal = qty * unitPrice.
- If only one price is shown per item line, use it as subtotal and set unitPrice = subtotal / qty.
- Ignore tax lines, discount lines, change/kembalian lines, and subtotal/total summary lines from items.
- All amounts should be plain numbers without currency symbols or thousand separators (e.g. 15000 not "Rp 15.000").
- Indonesian receipt patterns: "Rp", "x", "@" for qty/unit price indicators.

Return ONLY the JSON object, no explanation or markdown.`;
}

// ─────────────────────────────────────────────────────
// JSON sanitizer — strip markdown code fences
// ─────────────────────────────────────────────────────

function sanitizeJson(raw: string): string {
  let cleaned = raw.trim();
  // Remove ```json ... ``` or ``` ... ```
  cleaned = cleaned.replace(/^```(?:json)?\s*\n?/i, '');
  cleaned = cleaned.replace(/\n?```\s*$/i, '');
  return cleaned.trim();
}

// ─────────────────────────────────────────────────────
// AI Provider calls
// ─────────────────────────────────────────────────────

async function callGemini(prompt: string): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
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
    const parsed = JSON.parse(sanitizeJson(rawText));

    return { data: parsed, provider: 'gemini' };
  } finally {
    clearTimeout(timeout);
  }
}

async function callGroq(prompt: string): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GROQ_TIMEOUT_MS);

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
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.1,
        response_format: { type: 'json_object' },
      }),
    });

    if (!res.ok) {
      throw new Error(`Groq HTTP ${res.status}: ${await res.text()}`);
    }

    const json = await res.json();
    const rawText = json?.choices?.[0]?.message?.content ?? '';
    const parsed = JSON.parse(sanitizeJson(rawText));

    return { data: parsed, provider: 'groq' };
  } finally {
    clearTimeout(timeout);
  }
}

// ─────────────────────────────────────────────────────
// Vision AI providers (untuk OCR mode — kirim gambar langsung)
// ─────────────────────────────────────────────────────

async function callGeminiVision(
  base64Image: string,
  mimeType: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { inline_data: { mime_type: mimeType, data: base64Image } },
                { text: buildOcrPromptForImage() },
              ],
            },
          ],
          generationConfig: { responseMimeType: 'application/json', temperature: 0.1 },
        }),
      },
    );

    if (!res.ok) {
      throw new Error(`Gemini Vision HTTP ${res.status}: ${await res.text()}`);
    }

    const json = await res.json();
    const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const parsed = JSON.parse(sanitizeJson(rawText));

    return { data: parsed, provider: 'gemini' };
  } finally {
    clearTimeout(timeout);
  }
}

async function callGroqVision(
  base64Image: string,
  mimeType: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GROQ_TIMEOUT_MS);

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
          {
            role: 'user',
            content: [
              {
                type: 'image_url',
                image_url: { url: `data:${mimeType};base64,${base64Image}` },
              },
              { type: 'text', text: buildOcrPromptForImage() },
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
    const parsed = JSON.parse(sanitizeJson(rawText));

    return { data: parsed, provider: 'groq' };
  } finally {
    clearTimeout(timeout);
  }
}

// ─────────────────────────────────────────────────────
// OpenRouter Vision provider (3rd fallback untuk OCR)
// ─────────────────────────────────────────────────────

async function callOpenRouterVision(
  base64Image: string,
  mimeType: string,
): Promise<{ data: unknown; provider: string }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), OPENROUTER_TIMEOUT_MS);

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
          {
            role: 'user',
            content: [
              {
                type: 'image_url',
                image_url: { url: `data:${mimeType};base64,${base64Image}` },
              },
              { type: 'text', text: buildOcrPromptForImage() },
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
    const parsed = JSON.parse(sanitizeJson(rawText));

    return { data: parsed, provider: 'openrouter' };
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

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Parse request body ──
    const body = await req.json();
    const mode: string = body.mode; // 'voice' | 'ocr'

    if (!mode) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing mode' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (mode !== 'voice' && mode !== 'ocr') {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid mode. Use "voice" or "ocr".' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Try AI providers based on mode ──
    let result: { data: unknown; provider: string };

    if (mode === 'voice') {
      // Voice: teks STT → Gemini/Groq text model
      const text: string = body.text;
      if (!text) {
        return new Response(
          JSON.stringify({ success: false, error: 'Missing text for voice mode' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      const prompt = buildVoicePrompt(text);
      try {
        result = await callGemini(prompt);
      } catch (geminiErr) {
        console.error('[ai-parse] Gemini failed:', geminiErr);
        try {
          result = await callGroq(prompt);
        } catch (groqErr) {
          console.error('[ai-parse] Groq failed:', groqErr);
          return new Response(
            JSON.stringify({ success: false, mode, error: 'AI_BUSY' }),
            { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
          );
        }
      }
    } else {
      // OCR: kirim gambar langsung ke Vision AI → lebih akurat dari teks
      const image: string = body.image;
      const mimeType: string = body.mimeType || 'image/jpeg';

      if (!image) {
        return new Response(
          JSON.stringify({ success: false, error: 'Missing image for ocr mode' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        );
      }

      try {
        result = await callGeminiVision(image, mimeType);
      } catch (geminiErr) {
        console.error('[ai-parse] Gemini Vision failed:', geminiErr);
        try {
          result = await callGroqVision(image, mimeType);
        } catch (groqErr) {
          console.error('[ai-parse] Groq Vision failed:', groqErr);
          try {
            result = await callOpenRouterVision(image, mimeType);
          } catch (openrouterErr) {
            console.error('[ai-parse] OpenRouter Vision failed:', openrouterErr);
            // Semua AI gagal → Flutter akan fallback ke ML Kit OCR lokal
            return new Response(
              JSON.stringify({ success: false, mode, error: 'AI_BUSY' }),
              { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
            );
          }
        }
      }
    }

    // ── Success response ──
    return new Response(
      JSON.stringify({
        success: true,
        mode,
        provider: result.provider,
        data: result.data,
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
