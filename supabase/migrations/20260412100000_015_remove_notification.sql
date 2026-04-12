-- ============================================================
-- Migration 015: Remove Notification Feature
-- Alasan: Fitur notifikasi lokal dihapus dari Flutter side.
--         Tabel, kolom, trigger, function, dan RLS policies
--         yang berkaitan tidak lagi diperlukan.
-- ============================================================

-- ─── 1. Drop trigger & function: seed_notification_settings ───
DROP TRIGGER IF EXISTS trg_seed_notification_settings ON public.users;
DROP FUNCTION IF EXISTS public.seed_notification_settings();

-- ─── 2. Drop notification_settings table ───
-- (akan cascade: trg_notification_settings_updated_at, RLS policies)
DROP TABLE IF EXISTS public.notification_settings CASCADE;

-- ─── 3. Remove notification_sent columns dari budgets ───
ALTER TABLE public.budgets
  DROP COLUMN IF EXISTS notification_sent_50,
  DROP COLUMN IF EXISTS notification_sent_80,
  DROP COLUMN IF EXISTS notification_sent_100;
