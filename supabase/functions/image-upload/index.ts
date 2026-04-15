/// Supabase Edge Function: image-upload
///
/// Upload gambar ke Supabase Storage (primary) atau Google Cloud Storage (fallback).
/// Fallback ke GCS dipicu ketika usage bucket 'attachments' >= STORAGE_LIMIT_MB.
///
/// Request:  POST { imageBase64: string, fileName: string, mimeType?: string }
/// Response: { url: string, storage: "supabase" | "gcs" }

import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// --- Env ---
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const STORAGE_LIMIT_BYTES =
  parseInt(Deno.env.get('STORAGE_LIMIT_MB') ?? '950', 10) * 1024 * 1024;
const GCS_SERVICE_ACCOUNT_JSON = Deno.env.get('GCS_SERVICE_ACCOUNT_JSON') ?? '';

// --- Constants ---
const SUPABASE_BUCKET = 'attachments';
const GCS_SCOPE = 'https://www.googleapis.com/auth/devstorage.read_write';
const GOOGLE_OAUTH_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const MAX_IMAGE_BYTES = 10 * 1024 * 1024; // 10 MB
const SIGNED_URL_SECONDS = 60 * 60 * 24 * 365; // 1 year

// Timeouts
const GCS_AUTH_TIMEOUT_MS = 10_000;
const GCS_UPLOAD_TIMEOUT_MS = 30_000;
const GCS_ACL_TIMEOUT_MS = 10_000;

// --- Error codes ---
const ErrorCode = {
  INVALID_REQUEST: 'INVALID_REQUEST',
  IMAGE_TOO_LARGE: 'IMAGE_TOO_LARGE',
  UNAUTHENTICATED: 'UNAUTHENTICATED',
  SUPABASE_UPLOAD_FAILED: 'SUPABASE_UPLOAD_FAILED',
  GCS_CONFIG_MISSING: 'GCS_CONFIG_MISSING',
  GCS_AUTH_FAILED: 'GCS_AUTH_FAILED',
  GCS_UPLOAD_FAILED: 'GCS_UPLOAD_FAILED',
} as const;

const USER_MESSAGES: Record<string, string> = {
  [ErrorCode.INVALID_REQUEST]: 'Permintaan tidak valid.',
  [ErrorCode.IMAGE_TOO_LARGE]: 'Ukuran gambar terlalu besar. Maksimum 10 MB.',
  [ErrorCode.UNAUTHENTICATED]: 'Sesi tidak valid. Silakan login ulang.',
  [ErrorCode.SUPABASE_UPLOAD_FAILED]: 'Gagal mengupload gambar. Coba lagi.',
  [ErrorCode.GCS_CONFIG_MISSING]: 'Gagal mengupload gambar. Coba lagi.',
  [ErrorCode.GCS_AUTH_FAILED]: 'Gagal mengupload gambar. Coba lagi.',
  [ErrorCode.GCS_UPLOAD_FAILED]: 'Gagal mengupload gambar. Coba lagi.',
};

function errorResponse(code: string, detail: string, status = 500): Response {
  console.error(`[image-upload] ${code}: ${detail}`);
  const userMessage = USER_MESSAGES[code] ?? 'Gagal mengupload gambar. Coba lagi.';
  return new Response(
    JSON.stringify({ success: false, error: userMessage }),
    { status, headers: { 'Content-Type': 'application/json' } },
  );
}

// --- Auth helpers ---

function getUserIdFromAuthHeader(authHeader: string): string | null {
  try {
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    // JWT already verified by Supabase edge runtime (verify_jwt: true)
    const payload = JSON.parse(atob(parts[1])) as { sub?: string };
    return payload.sub ?? null;
  } catch {
    return null;
  }
}

// --- GCS OAuth2 (pola dari gold-price) ---

interface GcsCredentials {
  clientEmail: string;
  privateKey: string;
  storageBucket: string;
}

let gcsTokenCache: { accessToken: string; expiresAtMs: number } | null = null;

function getGcsCredentials(): GcsCredentials {
  if (!GCS_SERVICE_ACCOUNT_JSON) {
    throw new Error('GCS_SERVICE_ACCOUNT_JSON is not configured');
  }
  const parsed = JSON.parse(GCS_SERVICE_ACCOUNT_JSON) as {
    client_email?: string;
    private_key?: string;
    storage_bucket?: string;
  };
  if (!parsed.client_email || !parsed.private_key || !parsed.storage_bucket) {
    throw new Error(
      'GCS_SERVICE_ACCOUNT_JSON missing required fields: client_email, private_key, storage_bucket',
    );
  }
  return {
    clientEmail: parsed.client_email,
    privateKey: parsed.private_key.replace(/\\n/g, '\n'),
    storageBucket: parsed.storage_bucket,
  };
}

function encodeBase64Url(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleanPem = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binary = atob(cleanPem);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function signServiceAccountJwt(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: clientEmail,
    scope: GCS_SCOPE,
    aud: GOOGLE_OAUTH_TOKEN_URL,
    exp: now + 3600,
    iat: now,
  };
  const unsigned = `${encodeBase64Url(JSON.stringify(header))}.${encodeBase64Url(JSON.stringify(payload))}`;
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${encodeBase64Url(new Uint8Array(signature))}`;
}

async function getGcsAccessToken(creds: GcsCredentials): Promise<string> {
  if (gcsTokenCache && gcsTokenCache.expiresAtMs > Date.now() + 60_000) {
    return gcsTokenCache.accessToken;
  }
  const assertion = await signServiceAccountJwt(creds.clientEmail, creds.privateKey);
  const res = await fetch(GOOGLE_OAUTH_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
    signal: AbortSignal.timeout(GCS_AUTH_TIMEOUT_MS),
  });
  if (!res.ok) {
    throw new Error(`GCS OAuth2 HTTP ${res.status}`);
  }
  const json = await res.json() as { access_token?: string; expires_in?: number };
  if (!json.access_token || !json.expires_in) {
    throw new Error('GCS OAuth2 response missing access_token or expires_in');
  }
  gcsTokenCache = {
    accessToken: json.access_token,
    expiresAtMs: Date.now() + json.expires_in * 1000,
  };
  return json.access_token;
}

// --- Storage usage check ---

async function getSupabaseStorageBytes(
  supabase: ReturnType<typeof createClient>,
): Promise<number> {
  const { data, error } = await supabase.rpc('get_attachments_storage_bytes');
  if (error) {
    console.error(`[image-upload] STORAGE_RPC_FAILED: ${error.message}`);
    return 0; // fail-open: assume 0 so we proceed with Supabase
  }
  return (data as number) ?? 0;
}

// --- GCS upload ---

function encodedGcsPath(path: string): string {
  // Encode each segment individually, keep '/' as separator
  return path.split('/').map(encodeURIComponent).join('/');
}

async function uploadToGcs(
  creds: GcsCredentials,
  accessToken: string,
  path: string,
  imageBytes: Uint8Array,
  mimeType: string,
): Promise<string> {
  const encodedName = encodeURIComponent(path); // full path encoded for query param / API path

  // Step 1: Upload
  const uploadRes = await fetch(
    `https://storage.googleapis.com/upload/storage/v1/b/${creds.storageBucket}/o?uploadType=media&name=${encodedName}`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': mimeType,
        'Content-Length': String(imageBytes.length),
      },
      body: imageBytes,
      signal: AbortSignal.timeout(GCS_UPLOAD_TIMEOUT_MS),
    },
  );

  if (!uploadRes.ok) {
    const body = await uploadRes.text().catch(() => '');
    throw new Error(`GCS upload HTTP ${uploadRes.status}: ${body}`);
  }

  // Step 2: Set ACL public (best-effort — skip if bucket uses Uniform Access)
  try {
    await fetch(
      `https://storage.googleapis.com/storage/v1/b/${creds.storageBucket}/o/${encodedName}/acl`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ entity: 'allUsers', role: 'READER' }),
        signal: AbortSignal.timeout(GCS_ACL_TIMEOUT_MS),
      },
    );
  } catch (err) {
    // If ACL fails (bucket may use Uniform Access with allUsers already set), continue
    console.warn(`[image-upload] GCS ACL patch skipped (may be OK): ${err}`);
  }

  // Step 3: Build public URL
  return `https://storage.googleapis.com/${creds.storageBucket}/${encodedGcsPath(path)}`;
}

// --- Main handler ---

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  if (req.method !== 'POST') {
    return errorResponse(ErrorCode.INVALID_REQUEST, `Method ${req.method} not allowed`, 405);
  }

  // Verify user identity from JWT (already validated by Supabase edge runtime)
  const authHeader = req.headers.get('Authorization') ?? '';
  const userId = getUserIdFromAuthHeader(authHeader);
  if (!userId) {
    return errorResponse(
      ErrorCode.UNAUTHENTICATED,
      'Missing or invalid Authorization header',
      401,
    );
  }

  // Parse & validate request body
  let body: { imageBase64?: unknown; fileName?: unknown; mimeType?: unknown };
  try {
    body = await req.json();
  } catch {
    return errorResponse(ErrorCode.INVALID_REQUEST, 'Request body is not valid JSON', 400);
  }

  const { imageBase64, fileName, mimeType = 'image/jpeg' } = body;

  if (typeof imageBase64 !== 'string' || imageBase64.length === 0) {
    return errorResponse(ErrorCode.INVALID_REQUEST, 'imageBase64 is required (string)', 400);
  }
  if (
    typeof fileName !== 'string' ||
    fileName.length === 0 ||
    fileName.length > 255
  ) {
    return errorResponse(
      ErrorCode.INVALID_REQUEST,
      `fileName is required and must be 1–255 chars (got: ${fileName})`,
      400,
    );
  }
  if (typeof mimeType !== 'string') {
    return errorResponse(ErrorCode.INVALID_REQUEST, 'mimeType must be a string', 400);
  }

  // Decode base64 → bytes
  let imageBytes: Uint8Array;
  try {
    const binary = atob(imageBase64);
    imageBytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) imageBytes[i] = binary.charCodeAt(i);
  } catch {
    return errorResponse(ErrorCode.INVALID_REQUEST, 'imageBase64 is not valid base64', 400);
  }

  if (imageBytes.length > MAX_IMAGE_BYTES) {
    return errorResponse(
      ErrorCode.IMAGE_TOO_LARGE,
      `Image ${imageBytes.length} bytes exceeds limit ${MAX_IMAGE_BYTES} bytes`,
      400,
    );
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const timestamp = Date.now();
  const path = `${userId}/${timestamp}_${fileName}`;

  // Check Supabase storage usage
  const usedBytes = await getSupabaseStorageBytes(supabase);
  const useGcs = usedBytes >= STORAGE_LIMIT_BYTES;

  console.log(
    `[image-upload] userId=${userId} file=${fileName} size=${imageBytes.length} usedBytes=${usedBytes} limit=${STORAGE_LIMIT_BYTES} useGcs=${useGcs}`,
  );

  // ─── Path A: Supabase Storage ────────────────────────────────────────────
  if (!useGcs) {
    try {
      const { error: uploadError } = await supabase.storage
        .from(SUPABASE_BUCKET)
        .upload(path, imageBytes, { contentType: mimeType as string, upsert: true });

      if (uploadError) {
        return errorResponse(ErrorCode.SUPABASE_UPLOAD_FAILED, uploadError.message);
      }

      const { data: signedData, error: signedError } = await supabase.storage
        .from(SUPABASE_BUCKET)
        .createSignedUrl(path, SIGNED_URL_SECONDS);

      if (signedError || !signedData?.signedUrl) {
        return errorResponse(
          ErrorCode.SUPABASE_UPLOAD_FAILED,
          signedError?.message ?? 'createSignedUrl returned null',
        );
      }

      console.log(`[image-upload] Supabase upload success: ${path}`);
      return new Response(
        JSON.stringify({ url: signedData.signedUrl, storage: 'supabase' }),
        { headers: { 'Content-Type': 'application/json' } },
      );
    } catch (err) {
      return errorResponse(ErrorCode.SUPABASE_UPLOAD_FAILED, String(err));
    }
  }

  // ─── Path B: GCS fallback ─────────────────────────────────────────────────
  let creds: GcsCredentials;
  try {
    creds = getGcsCredentials();
  } catch (err) {
    return errorResponse(ErrorCode.GCS_CONFIG_MISSING, String(err));
  }

  let accessToken: string;
  try {
    accessToken = await getGcsAccessToken(creds);
  } catch (err) {
    return errorResponse(ErrorCode.GCS_AUTH_FAILED, String(err));
  }

  try {
    const publicUrl = await uploadToGcs(creds, accessToken, path, imageBytes, mimeType as string);
    console.log(`[image-upload] GCS upload success: ${publicUrl}`);
    return new Response(
      JSON.stringify({ url: publicUrl, storage: 'gcs' }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return errorResponse(ErrorCode.GCS_UPLOAD_FAILED, String(err));
  }
});
