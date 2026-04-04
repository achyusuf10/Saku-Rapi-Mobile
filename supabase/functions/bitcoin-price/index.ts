/// Supabase Edge Function: bitcoin-price
///
/// Cronjob (every hour `0 * * * *`) untuk mengambil harga Bitcoin
/// dari Indodax dan CoinGecko → UPSERT ke bitcoin_prices.
///
/// Strategy:
/// - Thread 1: Indodax API (btcidr ticker)
/// - Thread 2: CoinGecko API (simple/price)
/// - UPSERT: INSERT ... ON CONFLICT(source) DO UPDATE
///   (tabel tetap kecil, hanya 2 row)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const FETCH_TIMEOUT_MS = 10000;

// ─────────────────────────────────────────────────────
// Source Fetchers
// ─────────────────────────────────────────────────────

async function fetchIndodax(): Promise<number | null> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

    const res = await fetch('https://indodax.com/api/ticker/btcidr', {
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();

    // Indodax returns { ticker: { last: "1234567890" } }
    const price = parseInt(data?.ticker?.last, 10);
    return isNaN(price) ? null : price;
  } catch {
    return null;
  }
}

async function fetchCoinGecko(): Promise<number | null> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

    const res = await fetch(
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=idr',
      { signal: controller.signal }
    );
    clearTimeout(timeout);

    if (!res.ok) return null;
    const data = await res.json();

    // { bitcoin: { idr: 1234567890 } }
    const price = data?.bitcoin?.idr;
    return typeof price === 'number' ? Math.round(price) : null;
  } catch {
    return null;
  }
}

// ─────────────────────────────────────────────────────
// Main Handler
// ─────────────────────────────────────────────────────

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch both sources in parallel
    const [indodaxPrice, coingeckoPrice] = await Promise.all([
      fetchIndodax(),
      fetchCoinGecko(),
    ]);

    const results: { source: string; status: string }[] = [];

    // UPSERT Indodax — INSERT ON CONFLICT(source) DO UPDATE
    if (indodaxPrice !== null) {
      const { error } = await supabase.rpc('upsert_bitcoin_price', {
        p_source: 'indodax',
        p_price_idr: indodaxPrice,
      });

      if (error) {
        // Fallback: try direct upsert
        const { error: directError } = await supabase
          .from('bitcoin_prices')
          .upsert(
            { source: 'indodax', price_idr: indodaxPrice, fetched_at: new Date().toISOString() },
            { onConflict: 'source' }
          );
        results.push({
          source: 'indodax',
          status: directError ? `error: ${directError.message}` : 'upserted_direct',
        });
      } else {
        results.push({ source: 'indodax', status: 'upserted' });
      }
    } else {
      results.push({ source: 'indodax', status: 'fetch_failed' });
    }

    // UPSERT CoinGecko
    if (coingeckoPrice !== null) {
      const { error } = await supabase.rpc('upsert_bitcoin_price', {
        p_source: 'coingecko',
        p_price_idr: coingeckoPrice,
      });

      if (error) {
        const { error: directError } = await supabase
          .from('bitcoin_prices')
          .upsert(
            { source: 'coingecko', price_idr: coingeckoPrice, fetched_at: new Date().toISOString() },
            { onConflict: 'source' }
          );
        results.push({
          source: 'coingecko',
          status: directError ? `error: ${directError.message}` : 'upserted_direct',
        });
      } else {
        results.push({ source: 'coingecko', status: 'upserted' });
      }
    } else {
      results.push({ source: 'coingecko', status: 'fetch_failed' });
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
