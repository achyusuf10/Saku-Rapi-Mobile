-- Enforce max 10 rows per batch (aligns with app constant).
CREATE OR REPLACE FUNCTION public.create_transactions_batch(p_transactions jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  elem jsonb;
  v_wallet_id uuid;
  v_dest_id uuid;
  v_type text;
  v_total numeric;
  v_date timestamptz;
  v_items jsonb;
  v_items_sum numeric;
  v_txn_id uuid;
  v_item jsonb;
  v_ids uuid[] := '{}';
  v_ref uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_transactions IS NULL OR jsonb_typeof(p_transactions) <> 'array' THEN
    RAISE EXCEPTION 'p_transactions must be a json array';
  END IF;

  IF jsonb_array_length(p_transactions) < 1 THEN
    RAISE EXCEPTION 'At least one transaction required';
  END IF;

  IF jsonb_array_length(p_transactions) > 10 THEN
    RAISE EXCEPTION 'Maximum 10 transactions per batch';
  END IF;

  FOR elem IN SELECT * FROM jsonb_array_elements(p_transactions)
  LOOP
    v_wallet_id := (elem->>'wallet_id')::uuid;
    v_dest_id := CASE
      WHEN elem ? 'destination_wallet_id'
        AND NULLIF(TRIM(elem->>'destination_wallet_id'), '') IS NOT NULL
      THEN (elem->>'destination_wallet_id')::uuid
      ELSE NULL
    END;
    v_type := COALESCE(elem->>'type', 'expense');
    v_total := (elem->>'total_amount')::numeric;
    v_date := COALESCE((elem->>'date')::timestamptz, NOW());
    v_items := COALESCE(elem->'items', '[]'::jsonb);

    IF v_type NOT IN ('expense', 'income') THEN
      RAISE EXCEPTION 'Batch only supports expense and income (got %)', v_type;
    END IF;

    IF jsonb_array_length(v_items) = 0 THEN
      RAISE EXCEPTION 'Transaction must have at least 1 item';
    END IF;

    SELECT COALESCE(SUM((item->>'amount')::numeric), 0)
    INTO v_items_sum
    FROM jsonb_array_elements(v_items) AS item;

    IF v_items_sum != v_total THEN
      RAISE EXCEPTION 'Items sum (%) does not match total_amount (%)', v_items_sum, v_total;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.wallets w
      WHERE w.id = v_wallet_id AND w.user_id = v_user_id
    ) THEN
      RAISE EXCEPTION 'Wallet not found or not owned by user';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(v_items)
    LOOP
      IF (v_item->>'category_id') IS NULL OR (v_item->>'category_id') = '' THEN
        RAISE EXCEPTION 'Category required for every item';
      END IF;
    END LOOP;

    v_ref := CASE
      WHEN elem ? 'reference_transaction_id'
        AND NULLIF(TRIM(elem->>'reference_transaction_id'), '') IS NOT NULL
      THEN (elem->>'reference_transaction_id')::uuid
      ELSE NULL
    END;

    INSERT INTO public.transactions (
      user_id,
      wallet_id,
      destination_wallet_id,
      type,
      total_amount,
      date,
      merchant_name,
      note,
      attachment_url,
      with_person,
      status,
      due_date,
      is_multi_item,
      reference_transaction_id,
      settlement_kind,
      contact_id
    ) VALUES (
      v_user_id,
      v_wallet_id,
      v_dest_id,
      v_type,
      v_total,
      v_date,
      elem->>'merchant_name',
      elem->>'note',
      elem->>'attachment_url',
      elem->>'with_person',
      elem->>'status',
      CASE
        WHEN NULLIF(TRIM(elem->>'due_date'), '') IS NULL THEN NULL
        ELSE (elem->>'due_date')::date
      END,
      COALESCE((elem->>'is_multi_item')::boolean, false),
      v_ref,
      elem->>'settlement_kind',
      CASE
        WHEN elem ? 'contact_id'
          AND NULLIF(TRIM(elem->>'contact_id'), '') IS NOT NULL
        THEN (elem->>'contact_id')::uuid
        ELSE NULL
      END
    )
    RETURNING id INTO v_txn_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(v_items)
    LOOP
      INSERT INTO public.transaction_items (
        transaction_id,
        category_id,
        item_name,
        qty,
        unit_price,
        amount,
        note,
        sort_order
      ) VALUES (
        v_txn_id,
        (v_item->>'category_id')::uuid,
        v_item->>'item_name',
        COALESCE((v_item->>'qty')::numeric, 1),
        (v_item->>'unit_price')::numeric,
        (v_item->>'amount')::numeric,
        v_item->>'note',
        COALESCE((v_item->>'sort_order')::integer, 0)
      );
    END LOOP;

    v_ids := array_append(v_ids, v_txn_id);
  END LOOP;

  RETURN jsonb_build_object(
    'transaction_ids', to_jsonb(v_ids),
    'count', cardinality(v_ids)
  );
END;
$function$;
