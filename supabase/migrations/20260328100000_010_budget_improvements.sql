-- ============================================================
-- Migration: Budget Feature Improvements
-- Issues: 7.1–7.14 from 04_BUDGET_ANALYSIS.md
-- ============================================================

-- ─── 1. Add new columns to budgets table ───
ALTER TABLE public.budgets
  ADD COLUMN IF NOT EXISTS notification_sent_50 boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS carry_forward boolean NOT NULL DEFAULT false;

-- ─── 2. Add budget_alert_50_enabled to notification_settings ───
ALTER TABLE public.notification_settings
  ADD COLUMN IF NOT EXISTS budget_alert_50_enabled boolean NOT NULL DEFAULT false;

-- ─── 3. RPC: replace_budget (atomic delete + insert) ───
CREATE OR REPLACE FUNCTION public.replace_budget(
  p_old_budget_id uuid,
  p_user_id uuid,
  p_category_id uuid,
  p_wallet_id uuid,
  p_amount numeric,
  p_start_date date,
  p_end_date date,
  p_is_recurring boolean,
  p_period_type text,
  p_carry_forward boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_id uuid;
  v_result jsonb;
BEGIN
  -- Delete old budget
  DELETE FROM public.budgets WHERE id = p_old_budget_id AND user_id = p_user_id;

  -- Insert new budget
  INSERT INTO public.budgets (
    user_id, category_id, wallet_id, amount,
    start_date, end_date, is_recurring, period_type, carry_forward
  ) VALUES (
    p_user_id, p_category_id, p_wallet_id, p_amount,
    p_start_date, p_end_date, p_is_recurring, p_period_type, p_carry_forward
  )
  RETURNING id INTO v_new_id;

  -- Return the new budget with joins
  SELECT to_jsonb(b) || jsonb_build_object(
    'categories', to_jsonb(c),
    'wallets', to_jsonb(w)
  )
  INTO v_result
  FROM public.budgets b
  LEFT JOIN public.categories c ON c.id = b.category_id
  LEFT JOIN public.wallets w ON w.id = b.wallet_id
  WHERE b.id = v_new_id;

  RETURN v_result;
END;
$$;

-- ─── 4. Updated trigger: update_budget_usage (includes child categories) ───
CREATE OR REPLACE FUNCTION public.update_budget_usage()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_category_id uuid;
  v_date date;
BEGIN
  -- Determine category and date based on operation
  IF TG_OP = 'DELETE' THEN
    v_category_id := OLD.category_id;
    v_date := OLD.date;
  ELSE
    v_category_id := NEW.category_id;
    v_date := NEW.date;
  END IF;

  -- Update all active budgets that match this category OR its parent
  UPDATE public.budgets b
  SET used_amount = COALESCE((
    SELECT SUM(ABS(t.amount))
    FROM public.transactions t
    WHERE t.category_id IN (
      SELECT id FROM public.categories
      WHERE id = b.category_id OR parent_id = b.category_id
    )
    AND t.date >= b.start_date
    AND t.date <= b.end_date
    AND (b.wallet_id IS NULL OR t.wallet_id = b.wallet_id)
  ), 0)
  WHERE b.start_date <= v_date
    AND b.end_date >= v_date
    AND (
      b.category_id = v_category_id
      OR b.category_id = (
        SELECT parent_id FROM public.categories WHERE id = v_category_id
      )
    );

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- ─── 5. Updated trigger: auto_renew_budgets (smart recurring + carry forward) ───
CREATE OR REPLACE FUNCTION public.auto_renew_budgets()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  r RECORD;
  v_new_start date;
  v_new_end date;
  v_duration int;
  v_new_amount numeric;
  v_remaining numeric;
BEGIN
  FOR r IN
    SELECT * FROM public.budgets
    WHERE is_recurring = true
      AND end_date < CURRENT_DATE
  LOOP
    -- Calculate new period based on period_type
    CASE r.period_type
      WHEN 'weekly' THEN
        v_new_start := r.end_date + 1;
        v_new_end := v_new_start + 6;
      WHEN 'monthly' THEN
        v_new_start := r.end_date + 1;
        v_new_end := (v_new_start + interval '1 month' - interval '1 day')::date;
      WHEN 'quarterly' THEN
        v_new_start := r.end_date + 1;
        v_new_end := (v_new_start + interval '3 months' - interval '1 day')::date;
      WHEN 'yearly' THEN
        v_new_start := r.end_date + 1;
        v_new_end := (v_new_start + interval '1 year' - interval '1 day')::date;
      WHEN 'custom' THEN
        v_duration := r.end_date - r.start_date;
        v_new_start := r.end_date + 1;
        -- Smart: if original end was last day of month, snap to end of month
        IF r.end_date = (date_trunc('month', r.end_date) + interval '1 month' - interval '1 day')::date THEN
          v_new_end := (date_trunc('month', v_new_start) + interval '1 month' - interval '1 day')::date;
        ELSE
          v_new_end := v_new_start + v_duration;
        END IF;
      ELSE
        v_new_start := r.end_date + 1;
        v_new_end := (v_new_start + interval '1 month' - interval '1 day')::date;
    END CASE;

    -- Calculate new amount (with optional carry forward)
    v_new_amount := r.amount;
    IF r.carry_forward THEN
      v_remaining := r.amount - r.used_amount;
      IF v_remaining > 0 THEN
        v_new_amount := r.amount + v_remaining;
      END IF;
    END IF;

    -- Insert new budget
    INSERT INTO public.budgets (
      user_id, category_id, wallet_id, amount,
      start_date, end_date, is_recurring, period_type, carry_forward
    ) VALUES (
      r.user_id, r.category_id, r.wallet_id, v_new_amount,
      v_new_start, v_new_end, true, r.period_type, r.carry_forward
    );

    -- Mark old budget as non-recurring (archived)
    UPDATE public.budgets SET is_recurring = false WHERE id = r.id;
  END LOOP;
END;
$$;

-- ─── 6. Enable pg_cron and schedule auto-renew ───
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;

-- Schedule: run daily at 00:05 UTC (17:05 WIB)
SELECT cron.schedule(
  'auto-renew-budgets',
  '5 17 * * *',
  $$SELECT public.auto_renew_budgets()$$
);
