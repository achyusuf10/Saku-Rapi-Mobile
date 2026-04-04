-- Migration: Add update_settlement and delete_settlement RPCs
-- These RPCs handle editing/deleting settlement transactions
-- and recalculating the parent debt/loan status.

-- RPC: update_settlement
CREATE OR REPLACE FUNCTION public.update_settlement(
  p_settlement_id uuid,
  p_amount numeric,
  p_wallet_id uuid,
  p_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_settlement record;
  v_ref_txn record;
  v_other_settled numeric;
  v_new_total_settled numeric;
  v_new_status text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id, reference_transaction_id, settlement_kind, total_amount, wallet_id
  INTO v_settlement
  FROM public.transactions
  WHERE id = p_settlement_id
    AND user_id = v_user_id
    AND settlement_kind IS NOT NULL;

  IF v_settlement IS NULL THEN
    RAISE EXCEPTION 'Settlement transaction not found or not owned by user';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Settlement amount must be positive';
  END IF;

  SELECT id, total_amount
  INTO v_ref_txn
  FROM public.transactions
  WHERE id = v_settlement.reference_transaction_id
    AND user_id = v_user_id;

  IF v_ref_txn IS NULL THEN
    RAISE EXCEPTION 'Reference transaction not found';
  END IF;

  SELECT COALESCE(SUM(total_amount), 0) INTO v_other_settled
  FROM public.transactions
  WHERE reference_transaction_id = v_settlement.reference_transaction_id
    AND settlement_kind = v_settlement.settlement_kind
    AND id != p_settlement_id
    AND user_id = v_user_id;

  IF (v_other_settled + p_amount) > v_ref_txn.total_amount THEN
    RAISE EXCEPTION 'Settlement total (%) would exceed original principal (%)',
      v_other_settled + p_amount, v_ref_txn.total_amount;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.wallets WHERE id = p_wallet_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Wallet not found or not owned by user';
  END IF;

  UPDATE public.transactions
  SET total_amount = p_amount,
      wallet_id = p_wallet_id,
      note = p_note
  WHERE id = p_settlement_id AND user_id = v_user_id;

  UPDATE public.transaction_items
  SET amount = p_amount,
      note = p_note
  WHERE transaction_id = p_settlement_id;

  v_new_total_settled := v_other_settled + p_amount;
  v_new_status := CASE
    WHEN v_new_total_settled >= v_ref_txn.total_amount THEN 'paid'
    WHEN v_new_total_settled > 0 THEN 'partial'
    ELSE 'unpaid'
  END;

  UPDATE public.transactions
  SET status = v_new_status
  WHERE id = v_settlement.reference_transaction_id AND user_id = v_user_id;

  RETURN jsonb_build_object(
    'settlement_id', p_settlement_id,
    'reference_transaction_id', v_settlement.reference_transaction_id,
    'new_amount', p_amount,
    'total_settled', v_new_total_settled,
    'original_amount', v_ref_txn.total_amount,
    'new_status', v_new_status
  );
END;
$$;

-- RPC: delete_settlement
CREATE OR REPLACE FUNCTION public.delete_settlement(
  p_settlement_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_settlement record;
  v_ref_txn record;
  v_remaining_settled numeric;
  v_new_status text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id, reference_transaction_id, settlement_kind, total_amount
  INTO v_settlement
  FROM public.transactions
  WHERE id = p_settlement_id
    AND user_id = v_user_id
    AND settlement_kind IS NOT NULL;

  IF v_settlement IS NULL THEN
    RAISE EXCEPTION 'Settlement transaction not found or not owned by user';
  END IF;

  SELECT id, total_amount
  INTO v_ref_txn
  FROM public.transactions
  WHERE id = v_settlement.reference_transaction_id
    AND user_id = v_user_id;

  IF v_ref_txn IS NULL THEN
    RAISE EXCEPTION 'Reference transaction not found';
  END IF;

  DELETE FROM public.transactions
  WHERE id = p_settlement_id AND user_id = v_user_id;

  SELECT COALESCE(SUM(total_amount), 0) INTO v_remaining_settled
  FROM public.transactions
  WHERE reference_transaction_id = v_settlement.reference_transaction_id
    AND settlement_kind IS NOT NULL
    AND user_id = v_user_id;

  v_new_status := CASE
    WHEN v_remaining_settled >= v_ref_txn.total_amount THEN 'paid'
    WHEN v_remaining_settled > 0 THEN 'partial'
    ELSE 'unpaid'
  END;

  UPDATE public.transactions
  SET status = v_new_status
  WHERE id = v_settlement.reference_transaction_id AND user_id = v_user_id;

  RETURN jsonb_build_object(
    'settlement_id', p_settlement_id,
    'reference_transaction_id', v_settlement.reference_transaction_id,
    'deleted', true,
    'total_settled', v_remaining_settled,
    'original_amount', v_ref_txn.total_amount,
    'new_status', v_new_status
  );
END;
$$;
