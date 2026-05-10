
-- Soft delete markers on public.users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS account_deleted boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS account_deleted_at timestamptz NULL;

COMMENT ON COLUMN public.users.account_deleted IS 'True when user requested account deletion (soft delete).';
COMMENT ON COLUMN public.users.account_deleted_at IS 'UTC timestamp when soft delete was requested; null when active.';

-- Idempotent soft delete for the authenticated user
CREATE OR REPLACE FUNCTION public.soft_delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.users
  SET
    account_deleted = true,
    account_deleted_at = COALESCE(account_deleted_at, timezone('utc', now())),
    updated_at = timezone('utc', now())
  WHERE id = uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found';
  END IF;
END;
$$;

-- Post-login / session gate: cooldown 30 days, then auto reactivate
CREATE OR REPLACE FUNCTION public.resolve_account_login_state()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  del_at timestamptz;
  is_del boolean;
  ends_at timestamptz;
BEGIN
  IF uid IS NULL THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'not_authenticated',
      'days_remaining', null::int
    );
  END IF;

  SELECT account_deleted, account_deleted_at
  INTO is_del, del_at
  FROM public.users
  WHERE id = uid;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'allowed', true,
      'reason', null,
      'days_remaining', null::int
    );
  END IF;

  IF NOT is_del OR del_at IS NULL THEN
    RETURN jsonb_build_object(
      'allowed', true,
      'reason', null,
      'days_remaining', null::int
    );
  END IF;

  ends_at := del_at + interval '30 days';

  IF timezone('utc', now()) >= ends_at THEN
    UPDATE public.users
    SET
      account_deleted = false,
      account_deleted_at = null,
      updated_at = timezone('utc', now())
    WHERE id = uid;

    RETURN jsonb_build_object(
      'allowed', true,
      'reason', 'reactivated',
      'days_remaining', null::int
    );
  END IF;

  RETURN jsonb_build_object(
    'allowed', false,
    'reason', 'account_cooldown',
    'days_remaining', greatest(
      1,
      ceil(extract(epoch FROM (ends_at - timezone('utc', now()))) / 86400.0)::int
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.soft_delete_own_account() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resolve_account_login_state() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.soft_delete_own_account() TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_account_login_state() TO authenticated;
