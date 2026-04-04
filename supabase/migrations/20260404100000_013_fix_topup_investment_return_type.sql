-- ============================================================================
-- Migration 013: Fix topup_investment return type bug
-- ============================================================================
-- Bug: v_total_cost was declared as numeric but reused to store to_jsonb()
-- result (jsonb). PostgreSQL raised "invalid input syntax for type numeric"
-- Fix: Added separate v_result jsonb variable for the function return value.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.topup_investment(
  p_asset_id uuid,
  p_units numeric,
  p_price_per_unit numeric,
  p_fee numeric DEFAULT 0,
  p_date timestamp with time zone DEFAULT now(),
  p_note text DEFAULT NULL,
  p_deduct_wallet boolean DEFAULT false,
  p_wallet_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id       uuid := auth.uid();
  v_asset         record;
  v_tx_id         uuid;
  v_wallet_tx_id  uuid := NULL;
  v_total_cost    numeric;
  v_result        jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_units <= 0 THEN
    RAISE EXCEPTION 'Units must be greater than 0';
  END IF;

  -- Validate asset ownership
  SELECT * INTO v_asset
  FROM public.investment_assets
  WHERE id = p_asset_id AND user_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Asset not found or not owned by user';
  END IF;

  v_total_cost := (p_units * p_price_per_unit) + p_fee;

  -- Validate wallet if deducting
  IF p_deduct_wallet AND p_wallet_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.wallets WHERE id = p_wallet_id AND user_id = v_user_id
    ) THEN
      RAISE EXCEPTION 'Wallet not found or not owned by user';
    END IF;
  END IF;

  -- Create wallet transaction if deducting
  IF p_deduct_wallet AND p_wallet_id IS NOT NULL THEN
    INSERT INTO public.transactions (
      user_id, wallet_id, type, total_amount, date,
      note, is_multi_item
    ) VALUES (
      v_user_id, p_wallet_id, 'transfer_to_asset', v_total_cost, p_date,
      'Top Up: ' || v_asset.name, false
    )
    RETURNING id INTO v_wallet_tx_id;

    INSERT INTO public.transaction_items (
      transaction_id, item_name, qty, amount, sort_order
    ) VALUES (
      v_wallet_tx_id, 'Top Up: ' || v_asset.name, 1, v_total_cost, 0
    );
  END IF;

  -- Create buy transaction
  INSERT INTO public.investment_transactions (
    asset_id, user_id, direction, units, price_per_unit, fee,
    wallet_id, deduct_wallet, linked_wallet_transaction_id, date, note
  ) VALUES (
    p_asset_id, v_user_id, 'buy', p_units, p_price_per_unit, p_fee,
    p_wallet_id, p_deduct_wallet, v_wallet_tx_id, p_date, p_note
  )
  RETURNING id INTO v_tx_id;

  -- Reactivate asset if it was inactive
  IF NOT v_asset.is_active THEN
    UPDATE public.investment_assets
    SET is_active = true
    WHERE id = p_asset_id;
  END IF;

  SELECT to_jsonb(t) INTO STRICT v_result
  FROM public.investment_transactions t WHERE t.id = v_tx_id;

  RETURN v_result;
END;
$function$;
