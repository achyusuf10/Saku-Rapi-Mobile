-- ============================================================================
-- Migration 014: Fix sell_investment return type bug
-- ============================================================================
-- Bug: v_proceeds was declared as numeric but reused for jsonb_build_object()
-- Same pattern as Migration 013 (topup_investment).
-- Fix: Added separate v_result jsonb variable for the function return value.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sell_investment(
  p_asset_id uuid,
  p_units numeric,
  p_price_per_unit numeric,
  p_date timestamp with time zone DEFAULT now(),
  p_note text DEFAULT NULL,
  p_credit_wallet boolean DEFAULT false,
  p_wallet_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id          uuid := auth.uid();
  v_asset            record;
  v_total_buy_units  numeric;
  v_total_sell_units numeric;
  v_remaining        numeric;
  v_tx_id            uuid;
  v_wallet_tx_id     uuid := NULL;
  v_proceeds         numeric;
  v_result           jsonb;
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

  -- Calculate remaining units
  SELECT COALESCE(SUM(CASE WHEN direction = 'buy' THEN units ELSE 0 END), 0),
         COALESCE(SUM(CASE WHEN direction = 'sell' THEN units ELSE 0 END), 0)
  INTO v_total_buy_units, v_total_sell_units
  FROM public.investment_transactions
  WHERE asset_id = p_asset_id;

  v_remaining := v_total_buy_units - v_total_sell_units;

  IF p_units > v_remaining THEN
    RAISE EXCEPTION 'Insufficient units. Available: %, Requested: %', v_remaining, p_units;
  END IF;

  v_proceeds := p_units * p_price_per_unit;

  -- Validate wallet if crediting
  IF p_credit_wallet AND p_wallet_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.wallets WHERE id = p_wallet_id AND user_id = v_user_id
    ) THEN
      RAISE EXCEPTION 'Wallet not found or not owned by user';
    END IF;

    -- Create income transaction to credit wallet
    INSERT INTO public.transactions (
      user_id, wallet_id, type, total_amount, date,
      note, is_multi_item
    ) VALUES (
      v_user_id, p_wallet_id, 'income', v_proceeds, p_date,
      'Sell: ' || v_asset.name, false
    )
    RETURNING id INTO v_wallet_tx_id;

    INSERT INTO public.transaction_items (
      transaction_id, item_name, qty, amount, sort_order
    ) VALUES (
      v_wallet_tx_id, 'Sell: ' || v_asset.name, 1, v_proceeds, 0
    );
  END IF;

  -- Create sell transaction
  INSERT INTO public.investment_transactions (
    asset_id, user_id, direction, units, price_per_unit, fee,
    wallet_id, deduct_wallet, linked_wallet_transaction_id, date, note
  ) VALUES (
    p_asset_id, v_user_id, 'sell', p_units, p_price_per_unit, 0,
    p_wallet_id, p_credit_wallet, v_wallet_tx_id, p_date, p_note
  )
  RETURNING id INTO v_tx_id;

  -- Check if asset should be deactivated
  IF (v_remaining - p_units) = 0 THEN
    UPDATE public.investment_assets
    SET is_active = false
    WHERE id = p_asset_id;
  END IF;

  v_result := jsonb_build_object(
    'transaction_id', v_tx_id,
    'remaining_units', v_remaining - p_units,
    'is_active', (v_remaining - p_units) > 0,
    'proceeds', v_proceeds,
    'wallet_credited', p_credit_wallet
  );

  RETURN v_result;
END;
$function$;
