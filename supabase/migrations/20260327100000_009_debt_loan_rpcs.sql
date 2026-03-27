-- ════════════════════════════════════════════════════════════════════════════
-- Migration 009: Debt/Loan Summary & Detail RPCs
-- ════════════════════════════════════════════════════════════════════════════

-- ─── RPC: get_debt_loan_summary ───
-- Aggregate hutang/piutang per kontak (with_person).
CREATE OR REPLACE FUNCTION public.get_debt_loan_summary(
  p_type       text,
  p_wallet_id  uuid DEFAULT NULL
)
RETURNS TABLE(
  with_person       text,
  contact_id        uuid,
  transaction_count bigint,
  total_principal   numeric,
  total_settled     numeric,
  remaining         numeric,
  has_unpaid        boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_type NOT IN ('debt', 'loan') THEN
    RAISE EXCEPTION 'Invalid type: %. Must be debt or loan', p_type;
  END IF;

  RETURN QUERY
  WITH originals AS (
    SELECT t.id, t.with_person, t.contact_id, t.total_amount, t.status
    FROM public.transactions t
    WHERE t.user_id = v_user_id
      AND t.type = p_type
      AND t.settlement_kind IS NULL
      AND (p_wallet_id IS NULL OR t.wallet_id = p_wallet_id)
  ),
  settlements AS (
    SELECT
      s.reference_transaction_id,
      SUM(s.total_amount) AS settled_amount
    FROM public.transactions s
    WHERE s.user_id = v_user_id
      AND s.settlement_kind IS NOT NULL
      AND s.reference_transaction_id IN (SELECT o.id FROM originals o)
    GROUP BY s.reference_transaction_id
  )
  SELECT
    o.with_person,
    MAX(o.contact_id::text)::uuid AS contact_id,
    COUNT(*)::bigint AS transaction_count,
    SUM(o.total_amount)::numeric AS total_principal,
    COALESCE(SUM(COALESCE(se.settled_amount, 0)), 0)::numeric AS total_settled,
    (SUM(o.total_amount) - COALESCE(SUM(COALESCE(se.settled_amount, 0)), 0))::numeric AS remaining,
    BOOL_OR(o.status IS DISTINCT FROM 'paid') AS has_unpaid
  FROM originals o
  LEFT JOIN settlements se ON se.reference_transaction_id = o.id
  GROUP BY o.with_person;
END;
$$;


-- ─── RPC: get_debt_loan_transactions_by_person ───
-- Get all debt/loan transactions (original) for a specific person.
CREATE OR REPLACE FUNCTION public.get_debt_loan_transactions_by_person(
  p_with_person text,
  p_type        text,
  p_wallet_id   uuid DEFAULT NULL
)
RETURNS TABLE(
  id                       uuid,
  wallet_id                uuid,
  wallet_name              text,
  type                     text,
  total_amount             numeric,
  date                     timestamptz,
  note                     text,
  with_person              text,
  contact_id               uuid,
  status                   text,
  due_date                 timestamptz,
  settlement_kind          text,
  reference_transaction_id uuid,
  total_settled            numeric,
  remaining                numeric,
  created_at               timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    t.id,
    t.wallet_id,
    w.name AS wallet_name,
    t.type,
    t.total_amount,
    t.date,
    t.note,
    t.with_person,
    t.contact_id,
    t.status,
    t.due_date,
    t.settlement_kind,
    t.reference_transaction_id,
    COALESCE((
      SELECT SUM(s.total_amount)
      FROM public.transactions s
      WHERE s.reference_transaction_id = t.id
        AND s.settlement_kind IS NOT NULL
        AND s.user_id = v_user_id
    ), 0)::numeric AS total_settled,
    (t.total_amount - COALESCE((
      SELECT SUM(s.total_amount)
      FROM public.transactions s
      WHERE s.reference_transaction_id = t.id
        AND s.settlement_kind IS NOT NULL
        AND s.user_id = v_user_id
    ), 0))::numeric AS remaining,
    t.created_at
  FROM public.transactions t
  JOIN public.wallets w ON w.id = t.wallet_id
  WHERE t.user_id = v_user_id
    AND t.with_person = p_with_person
    AND t.type = p_type
    AND t.settlement_kind IS NULL
    AND (p_wallet_id IS NULL OR t.wallet_id = p_wallet_id)
  ORDER BY t.date DESC, t.created_at DESC;
END;
$$;


-- ─── RPC: get_settlement_history ───
-- Get all settlement transactions for a specific original debt/loan transaction.
CREATE OR REPLACE FUNCTION public.get_settlement_history(
  p_reference_transaction_id uuid
)
RETURNS TABLE(
  id                       uuid,
  wallet_id                uuid,
  wallet_name              text,
  type                     text,
  total_amount             numeric,
  date                     timestamptz,
  note                     text,
  with_person              text,
  settlement_kind          text,
  reference_transaction_id uuid,
  created_at               timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.transactions t
    WHERE t.id = p_reference_transaction_id AND t.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Reference transaction not found';
  END IF;

  RETURN QUERY
  SELECT
    t.id,
    t.wallet_id,
    w.name AS wallet_name,
    t.type,
    t.total_amount,
    t.date,
    t.note,
    t.with_person,
    t.settlement_kind,
    t.reference_transaction_id,
    t.created_at
  FROM public.transactions t
  JOIN public.wallets w ON w.id = t.wallet_id
  WHERE t.user_id = v_user_id
    AND t.reference_transaction_id = p_reference_transaction_id
    AND t.settlement_kind IS NOT NULL
  ORDER BY t.date DESC, t.created_at DESC;
END;
$$;
