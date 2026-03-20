// /// Supabase Edge Function: ai-parse
// ///
// /// Menerima teks voice/OCR dan mengembalikan hasil parsing
// /// terstruktur dari AI (Gemini Flash → Groq Llama 3.3 failover).

// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
// const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY') ?? '';
// const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
// const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

// const GEMINI_TIMEOUT_MS = 8000;
// const GROQ_TIMEOUT_MS = 6000;

// // ─────────────────────────────────────────────────────
// // Prompt builders
// // ─────────────────────────────────────────────────────

// function buildVoicePrompt(text: string): string {
//   return `You are a financial transaction parser. Extract transaction information from the following voice input text (in Indonesian/English).

// Return a JSON object with these exact fields:
// {
//   "amount": <number or null>,
//   "categoryKeyword": "<single lowercase keyword for category, e.g. makan, transportasi, belanja, gaji>",
//   "note": "<remaining descriptive text or null>",
//   "type": "<expense or income>"
// }

// Rules:
// - Default type is "expense". Use "income" only if words like "gaji", "terima", "dapat", "masuk", "bonus" appear.
// - Extract the monetary amount. Convert shorthand like "25rb" to 25000, "1.5jt" to 1500000.
// - categoryKeyword should be a single word describing the spending/income category.
// - note should contain remaining context not captured by other fields.

// Voice input: "${text}"

// Return ONLY the JSON object, no explanation or markdown.`;
// }

// function buildOcrPrompt(text: string): string {
//   return `You are a receipt/invoice parser. Extract structured data from the following OCR text of a receipt.

// Return a JSON object with these exact fields:
// {
//   "merchantName": "<store/merchant name or null>",
//   "date": "<transaction date in yyyy-MM-dd format or null>",
//   "grandTotal": <total amount as number or null>,
//   "items": [
//     { "name": "<item name>", "amount": <item price as number> }
//   ]
// }

// Rules:
// - Extract the merchant name (usually at the top of the receipt).
// - Extract the date in yyyy-MM-dd format.
// - grandTotal is the final total amount paid.
// - items are individual line items with their prices.
// - Ignore tax, discount, change lines from items.
// - All amounts should be plain numbers without currency symbols.

// OCR text:
// "${text}"

// Return ONLY the JSON object, no explanation or markdown.`;
// }

// // ─────────────────────────────────────────────────────
// // JSON sanitizer — strip markdown code fences
// // ─────────────────────────────────────────────────────

// function sanitizeJson(raw: string): string {
//   let cleaned = raw.trim();
//   // Remove ```json ... ``` or ``` ... ```
//   cleaned = cleaned.replace(/^```(?:json)?\s*\n?/i, '');
//   cleaned = cleaned.replace(/\n?```\s*$/i, '');
//   return cleaned.trim();
// }

// // ─────────────────────────────────────────────────────
// // AI Provider calls
// // ─────────────────────────────────────────────────────

// async function callGemini(prompt: string): Promise<{ data: unknown; provider: string }> {
//   const controller = new AbortController();
//   const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

//   try {
//     const res = await fetch(
//       `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`,
//       {
//         method: 'POST',
//         headers: { 'Content-Type': 'application/json' },
//         signal: controller.signal,
//         body: JSON.stringify({
//           contents: [{ parts: [{ text: prompt }] }],
//           generationConfig: {
//             responseMimeType: 'application/json',
//             temperature: 0.1,
//           },
//         }),
//       },
//     );

//     if (!res.ok) {
//       throw new Error(`Gemini HTTP ${res.status}: ${await res.text()}`);
//     }

//     const json = await res.json();
//     const rawText = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
//     const parsed = JSON.parse(sanitizeJson(rawText));

//     return { data: parsed, provider: 'gemini' };
//   } finally {
//     clearTimeout(timeout);
//   }
// }

// async function callGroq(prompt: string): Promise<{ data: unknown; provider: string }> {
//   const controller = new AbortController();
//   const timeout = setTimeout(() => controller.abort(), GROQ_TIMEOUT_MS);

//   try {
//     const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
//       method: 'POST',
//       headers: {
//         'Content-Type': 'application/json',
//         Authorization: `Bearer ${GROQ_API_KEY}`,
//       },
//       signal: controller.signal,
//       body: JSON.stringify({
//         model: 'llama-3.3-70b-versatile',
//         messages: [{ role: 'user', content: prompt }],
//         temperature: 0.1,
//         response_format: { type: 'json_object' },
//       }),
//     });

//     if (!res.ok) {
//       throw new Error(`Groq HTTP ${res.status}: ${await res.text()}`);
//     }

//     const json = await res.json();
//     const rawText = json?.choices?.[0]?.message?.content ?? '';
//     const parsed = JSON.parse(sanitizeJson(rawText));

//     return { data: parsed, provider: 'groq' };
//   } finally {
//     clearTimeout(timeout);
//   }
// }

// // ─────────────────────────────────────────────────────
// // CORS helpers
// // ─────────────────────────────────────────────────────

// const corsHeaders = {
//   'Access-Control-Allow-Origin': '*',
//   'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
// };

// // ─────────────────────────────────────────────────────
// // Main handler
// // ─────────────────────────────────────────────────────

// Deno.serve(async (req) => {
//   // CORS preflight
//   if (req.method === 'OPTIONS') {
//     return new Response('ok', { headers: corsHeaders });
//   }

//   try {
//     // ── JWT Validation ──
//     const authHeader = req.headers.get('Authorization');
//     if (!authHeader) {
//       return new Response(
//         JSON.stringify({ success: false, error: 'Missing authorization header' }),
//         { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
//       );
//     }

//     const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
//       global: { headers: { Authorization: authHeader } },
//     });

//     const { data: { user }, error: authError } = await supabase.auth.getUser();
//     if (authError || !user) {
//       return new Response(
//         JSON.stringify({ success: false, error: 'Unauthorized' }),
//         { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
//       );
//     }

//     // ── Parse request body ──
//     const body = await req.json();
//     const mode: string = body.mode; // 'voice' | 'ocr'
//     const text: string = body.text;

//     if (!mode || !text) {
//       return new Response(
//         JSON.stringify({ success: false, error: 'Missing mode or text' }),
//         { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
//       );
//     }

//     if (mode !== 'voice' && mode !== 'ocr') {
//       return new Response(
//         JSON.stringify({ success: false, error: 'Invalid mode. Use "voice" or "ocr".' }),
//         { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
//       );
//     }

//     // ── Build prompt ──
//     const prompt = mode === 'voice' ? buildVoicePrompt(text) : buildOcrPrompt(text);

//     // ── Try Gemini → Groq failover ──
//     let result: { data: unknown; provider: string };

//     try {
//       result = await callGemini(prompt);
//     } catch (geminiErr) {
//       console.error('[ai-parse] Gemini failed:', geminiErr);

//       try {
//         result = await callGroq(prompt);
//       } catch (groqErr) {
//         console.error('[ai-parse] Groq failed:', groqErr);

//         // Both providers failed → AI_BUSY
//         return new Response(
//           JSON.stringify({
//             success: false,
//             mode,
//             error: 'AI_BUSY',
//           }),
//           { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
//         );
//       }
//     }

//     // ── Success response ──
//     return new Response(
//       JSON.stringify({
//         success: true,
//         mode,
//         provider: result.provider,
//         data: result.data,
//       }),
//       { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
//     );
//   } catch (err) {
//     console.error('[ai-parse] Unhandled error:', err);
//     return new Response(
//       JSON.stringify({ success: false, error: 'Internal server error' }),
//       { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
//     );
//   }
// });
