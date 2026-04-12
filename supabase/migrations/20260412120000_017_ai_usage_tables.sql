-- Migration: AI Usage Tables + Tier System
-- Creates ai_usage_quotas, ai_usage_logs, ALTER users for subscription tiers

-- 1. ALTER users: add tier + tier_expires_at
ALTER TABLE public.users
  ADD COLUMN tier text NOT NULL DEFAULT 'free',
  ADD COLUMN tier_expires_at timestamptz DEFAULT NULL;

COMMENT ON COLUMN public.users.tier IS 'Subscription tier: free, premium, etc.';
COMMENT ON COLUMN public.users.tier_expires_at IS 'When current tier expires. NULL = permanent (free). Auto-downgrade on expiry.';

-- 2. CREATE ai_usage_quotas
CREATE TABLE public.ai_usage_quotas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tier text NOT NULL DEFAULT 'free',
  mode text NOT NULL,
  daily_limit integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(tier, mode)
);

COMMENT ON TABLE public.ai_usage_quotas IS 'Daily AI parse quota config per tier per mode.';

-- 3. CREATE ai_usage_logs
CREATE TABLE public.ai_usage_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  mode text NOT NULL,
  provider text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_ai_usage_logs_user_date
  ON public.ai_usage_logs (user_id, mode, created_at);

COMMENT ON TABLE public.ai_usage_logs IS 'Log setiap AI parse yang berhasil. Append-only.';

-- 4. RLS policies
ALTER TABLE public.ai_usage_quotas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_usage_quotas_select_all" ON public.ai_usage_quotas
  FOR SELECT TO authenticated USING (true);

ALTER TABLE public.ai_usage_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_usage_logs_select_own" ON public.ai_usage_logs
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- 5. Seed data
INSERT INTO public.ai_usage_quotas (tier, mode, daily_limit) VALUES
  ('free', 'text', 5),
  ('free', 'voice', 5),
  ('free', 'ocr', 3),
  ('premium', 'text', 20),
  ('premium', 'voice', 20),
  ('premium', 'ocr', 10);
