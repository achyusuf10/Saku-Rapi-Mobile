-- Migration: AI Quota RPC Functions
-- check_ai_quota, log_ai_usage, get_all_ai_quotas

-- RPC 1: check_ai_quota(p_mode) — cek kuota + auto-downgrade
CREATE OR REPLACE FUNCTION public.check_ai_quota(p_mode text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_tier text;
  v_expires_at timestamptz;
  v_daily_limit integer;
  v_today_count integer;
  v_today_start timestamptz;
  v_today_end timestamptz;
BEGIN
  SELECT tier, tier_expires_at INTO v_tier, v_expires_at
  FROM public.users WHERE id = v_user_id;
  IF v_tier IS NULL THEN v_tier := 'free'; END IF;

  -- Auto-downgrade if expired
  IF v_tier <> 'free' AND v_expires_at IS NOT NULL AND v_expires_at < now() THEN
    UPDATE public.users SET tier = 'free', tier_expires_at = NULL WHERE id = v_user_id;
    v_tier := 'free';
  END IF;

  SELECT daily_limit INTO v_daily_limit
  FROM public.ai_usage_quotas WHERE tier = v_tier AND mode = p_mode;
  IF v_daily_limit IS NULL THEN v_daily_limit := 0; END IF;

  v_today_start := date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta';
  v_today_end := v_today_start + interval '1 day';

  SELECT COUNT(*) INTO v_today_count FROM public.ai_usage_logs
  WHERE user_id = v_user_id AND mode = p_mode
    AND created_at >= v_today_start
    AND created_at < v_today_end;

  RETURN jsonb_build_object(
    'allowed', v_today_count < v_daily_limit,
    'used', v_today_count,
    'limit', v_daily_limit,
    'remaining', GREATEST(v_daily_limit - v_today_count, 0),
    'tier', v_tier
  );
END; $$;

-- RPC 2: log_ai_usage(p_mode, p_provider) — log after success
CREATE OR REPLACE FUNCTION public.log_ai_usage(p_mode text, p_provider text DEFAULT 'gemini')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_tier text;
  v_daily_limit integer;
  v_today_count integer;
  v_today_start timestamptz;
  v_today_end timestamptz;
BEGIN
  INSERT INTO public.ai_usage_logs (user_id, mode, provider)
  VALUES (v_user_id, p_mode, p_provider);

  SELECT tier INTO v_tier FROM public.users WHERE id = v_user_id;
  IF v_tier IS NULL THEN v_tier := 'free'; END IF;

  SELECT daily_limit INTO v_daily_limit
  FROM public.ai_usage_quotas WHERE tier = v_tier AND mode = p_mode;
  IF v_daily_limit IS NULL THEN v_daily_limit := 0; END IF;

  v_today_start := date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta';
  v_today_end := v_today_start + interval '1 day';

  SELECT COUNT(*) INTO v_today_count FROM public.ai_usage_logs
  WHERE user_id = v_user_id AND mode = p_mode
    AND created_at >= v_today_start
    AND created_at < v_today_end;

  RETURN jsonb_build_object(
    'used', v_today_count,
    'limit', v_daily_limit,
    'remaining', GREATEST(v_daily_limit - v_today_count, 0)
  );
END; $$;

-- RPC 3: get_all_ai_quotas() — fetch all quotas + auto-downgrade
CREATE OR REPLACE FUNCTION public.get_all_ai_quotas()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_tier text;
  v_expires_at timestamptz;
  v_result jsonb := '{}';
  v_mode text;
  v_daily_limit integer;
  v_today_count integer;
  v_today_start timestamptz;
  v_today_end timestamptz;
BEGIN
  SELECT tier, tier_expires_at INTO v_tier, v_expires_at
  FROM public.users WHERE id = v_user_id;
  IF v_tier IS NULL THEN v_tier := 'free'; END IF;

  IF v_tier <> 'free' AND v_expires_at IS NOT NULL AND v_expires_at < now() THEN
    UPDATE public.users SET tier = 'free', tier_expires_at = NULL WHERE id = v_user_id;
    v_tier := 'free';
  END IF;

  v_today_start := date_trunc('day', now() AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta';
  v_today_end := v_today_start + interval '1 day';

  FOR v_mode, v_daily_limit IN
    SELECT q.mode, q.daily_limit FROM public.ai_usage_quotas q WHERE q.tier = v_tier
  LOOP
    SELECT COUNT(*) INTO v_today_count FROM public.ai_usage_logs
    WHERE user_id = v_user_id AND mode = v_mode
      AND created_at >= v_today_start
      AND created_at < v_today_end;

    v_result := v_result || jsonb_build_object(
      v_mode, jsonb_build_object(
        'used', v_today_count,
        'limit', v_daily_limit,
        'remaining', GREATEST(v_daily_limit - v_today_count, 0)
      )
    );
  END LOOP;

  v_result := v_result || jsonb_build_object('tier', v_tier);

  RETURN v_result;
END; $$;
