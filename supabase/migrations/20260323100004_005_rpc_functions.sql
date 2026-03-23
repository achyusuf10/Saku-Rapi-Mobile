-- ============================================================================
-- SakuRapi Migration 005: RPC Functions (Atomic Writes)
-- ============================================================================
-- Sesuai 02_DATABASE.md §3.2:
--   - create_transaction_with_items(...)
--   - update_transaction_with_items(...)
--   - delete_transaction(...)
--   - create_adjustment_transaction(...)
--   - settle_debt_or_loan(...)
--   - create_investment_with_optional_wallet_deduction(...)
--
-- Rule: Flutter memanggil RPC ini via RemoteDataSource.
-- Jangan bangun multi-step write langsung dari client.
-- ============================================================================


-- ════════════════════════════════════════════════════════════════════════════
-- RPC 1: create_transaction_with_items
-- ════════════════════════════════════════════════════════════════════════════
-- Digunakan untuk: income, expense, transfer, debt, loan, transfer_to_asset.
-- Menjamin atomicity: transaction + items dalam satu DB transaction.
-- Trigger update_wallet_balance() otomatis fire setelah INSERT transaction.
-- Trigger update_budget_usage() otomatis fire setelah INSERT items.
--
-- Parameter items: JSONB array of objects:
--   [{ "category_id": uuid|null, "item_name": text|null, "qty": numeric,
--      "unit_price": numeric|null, "amount": numeric, "note": text|null,
--      "sort_order": integer }]
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.create_transaction_with_items(
  p_wallet_id             uuid,
  p_destination_wallet_id uuid default null,
  p_type                  text default 'expense',
  p_total_amount          numeric default 0,
  p_date                  timestamptz default now(),
  p_merchant_name         text default null,
  p_note                  text default null,
  p_attachment_url        text default null,
  p_with_person           text default null,
  p_status                text default null,
  p_due_date              timestamptz default null,
  p_is_multi_item         boolean default false,
  p_reference_transaction_id uuid default null,
  p_settlement_kind       text default null,
  p_items                 jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_txn_id uuid;
  v_item jsonb;
  v_items_sum numeric := 0;
  v_result jsonb;
begin
  -- ── Validate caller ──
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- ── Validate items array not empty ──
  if jsonb_array_length(p_items) = 0 then
    raise exception 'Transaction must have at least 1 item';
  end if;

  -- ── Validate items sum matches total_amount ──
  select coalesce(sum((item ->> 'amount')::numeric), 0)
  into v_items_sum
  from jsonb_array_elements(p_items) as item;

  if v_items_sum != p_total_amount then
    raise exception 'Items sum (%) does not match total_amount (%)',
      v_items_sum, p_total_amount;
  end if;

  -- ── Validate wallet ownership ──
  if not exists (
    select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
  ) then
    raise exception 'Wallet not found or not owned by user';
  end if;

  -- ── Validate destination wallet for transfer ──
  if p_type = 'transfer' then
    if p_destination_wallet_id is null then
      raise exception 'Transfer requires destination_wallet_id';
    end if;
    if p_wallet_id = p_destination_wallet_id then
      raise exception 'Cannot transfer to the same wallet';
    end if;
    if not exists (
      select 1 from public.wallets where id = p_destination_wallet_id and user_id = v_user_id
    ) then
      raise exception 'Destination wallet not found or not owned by user';
    end if;
  end if;

  -- ── Validate debt/loan requires with_person ──
  if p_type in ('debt', 'loan') and (p_with_person is null or trim(p_with_person) = '') then
    raise exception 'Debt/loan requires with_person';
  end if;

  -- ── Validate settlement constraints ──
  if p_settlement_kind is not null then
    if p_reference_transaction_id is null then
      raise exception 'Settlement requires reference_transaction_id';
    end if;
    if p_settlement_kind = 'debt_payment' and p_type != 'expense' then
      raise exception 'debt_payment settlement must be type expense';
    end if;
    if p_settlement_kind = 'loan_collection' and p_type != 'income' then
      raise exception 'loan_collection settlement must be type income';
    end if;
  end if;

  -- ── INSERT transaction (trigger fires update_wallet_balance) ──
  insert into public.transactions (
    user_id, wallet_id, destination_wallet_id, type, total_amount, date,
    merchant_name, note, attachment_url, with_person, status, due_date,
    is_multi_item, reference_transaction_id, settlement_kind
  ) values (
    v_user_id, p_wallet_id, p_destination_wallet_id, p_type, p_total_amount,
    p_date, p_merchant_name, p_note, p_attachment_url, p_with_person,
    p_status, p_due_date, p_is_multi_item, p_reference_transaction_id,
    p_settlement_kind
  )
  returning id into v_txn_id;

  -- ── INSERT items (trigger fires update_budget_usage per item) ──
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.transaction_items (
      transaction_id, category_id, item_name, qty, unit_price, amount, note, sort_order
    ) values (
      v_txn_id,
      (v_item ->> 'category_id')::uuid,
      v_item ->> 'item_name',
      coalesce((v_item ->> 'qty')::numeric, 1),
      (v_item ->> 'unit_price')::numeric,
      (v_item ->> 'amount')::numeric,
      v_item ->> 'note',
      coalesce((v_item ->> 'sort_order')::integer, 0)
    );
  end loop;

  -- ── Return the created transaction + items ──
  select jsonb_build_object(
    'transaction_id', v_txn_id,
    'wallet_id', p_wallet_id,
    'type', p_type,
    'total_amount', p_total_amount,
    'items_count', jsonb_array_length(p_items)
  ) into v_result;

  return v_result;
end;
$$;


-- ════════════════════════════════════════════════════════════════════════════
-- RPC 2: update_transaction_with_items
-- ════════════════════════════════════════════════════════════════════════════
-- Strategi: delete old items → update transaction header → insert new items.
-- Trigger wallet balance fires on UPDATE transaction.
-- Trigger budget usage fires on DELETE + INSERT items.
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.update_transaction_with_items(
  p_transaction_id        uuid,
  p_wallet_id             uuid,
  p_destination_wallet_id uuid default null,
  p_type                  text default 'expense',
  p_total_amount          numeric default 0,
  p_date                  timestamptz default now(),
  p_merchant_name         text default null,
  p_note                  text default null,
  p_attachment_url        text default null,
  p_with_person           text default null,
  p_status                text default null,
  p_due_date              timestamptz default null,
  p_is_multi_item         boolean default false,
  p_reference_transaction_id uuid default null,
  p_settlement_kind       text default null,
  p_items                 jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_item jsonb;
  v_items_sum numeric := 0;
begin
  -- ── Validate caller ──
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- ── Validate transaction ownership ──
  if not exists (
    select 1 from public.transactions
    where id = p_transaction_id and user_id = v_user_id
  ) then
    raise exception 'Transaction not found or not owned by user';
  end if;

  -- ── Validate items ──
  if jsonb_array_length(p_items) = 0 then
    raise exception 'Transaction must have at least 1 item';
  end if;

  select coalesce(sum((item ->> 'amount')::numeric), 0)
  into v_items_sum
  from jsonb_array_elements(p_items) as item;

  if v_items_sum != p_total_amount then
    raise exception 'Items sum (%) does not match total_amount (%)',
      v_items_sum, p_total_amount;
  end if;

  -- ── Validate wallet ownership ──
  if not exists (
    select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
  ) then
    raise exception 'Wallet not found or not owned by user';
  end if;

  -- ── Validate transfer ──
  if p_type = 'transfer' then
    if p_destination_wallet_id is null then
      raise exception 'Transfer requires destination_wallet_id';
    end if;
    if p_wallet_id = p_destination_wallet_id then
      raise exception 'Cannot transfer to the same wallet';
    end if;
  end if;

  -- ── Validate debt/loan ──
  if p_type in ('debt', 'loan') and (p_with_person is null or trim(p_with_person) = '') then
    raise exception 'Debt/loan requires with_person';
  end if;

  -- ── Validate settlement ──
  if p_settlement_kind is not null then
    if p_reference_transaction_id is null then
      raise exception 'Settlement requires reference_transaction_id';
    end if;
    if p_settlement_kind = 'debt_payment' and p_type != 'expense' then
      raise exception 'debt_payment settlement must be type expense';
    end if;
    if p_settlement_kind = 'loan_collection' and p_type != 'income' then
      raise exception 'loan_collection settlement must be type income';
    end if;
  end if;

  -- ── Delete old items (triggers budget recalc) ──
  delete from public.transaction_items
  where transaction_id = p_transaction_id;

  -- ── Update transaction header (triggers wallet balance recalc) ──
  update public.transactions set
    wallet_id = p_wallet_id,
    destination_wallet_id = p_destination_wallet_id,
    type = p_type,
    total_amount = p_total_amount,
    date = p_date,
    merchant_name = p_merchant_name,
    note = p_note,
    attachment_url = p_attachment_url,
    with_person = p_with_person,
    status = p_status,
    due_date = p_due_date,
    is_multi_item = p_is_multi_item,
    reference_transaction_id = p_reference_transaction_id,
    settlement_kind = p_settlement_kind
  where id = p_transaction_id and user_id = v_user_id;

  -- ── Insert new items ──
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.transaction_items (
      transaction_id, category_id, item_name, qty, unit_price, amount, note, sort_order
    ) values (
      p_transaction_id,
      (v_item ->> 'category_id')::uuid,
      v_item ->> 'item_name',
      coalesce((v_item ->> 'qty')::numeric, 1),
      (v_item ->> 'unit_price')::numeric,
      (v_item ->> 'amount')::numeric,
      v_item ->> 'note',
      coalesce((v_item ->> 'sort_order')::integer, 0)
    );
  end loop;

  return jsonb_build_object(
    'transaction_id', p_transaction_id,
    'updated', true,
    'items_count', jsonb_array_length(p_items)
  );
end;
$$;


-- ════════════════════════════════════════════════════════════════════════════
-- RPC 3: delete_transaction
-- ════════════════════════════════════════════════════════════════════════════
-- Delete a transaction and its items atomically.
-- Items cascade-delete automatically (FK ON DELETE CASCADE).
-- Wallet balance is reversed by trigger on DELETE.
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.delete_transaction(
  p_transaction_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_txn record;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Fetch transaction info before delete
  select id, type, settlement_kind, reference_transaction_id
  into v_txn
  from public.transactions
  where id = p_transaction_id and user_id = v_user_id;

  if v_txn is null then
    raise exception 'Transaction not found or not owned by user';
  end if;

  -- ── Guard: don't delete if this transaction has settlements referencing it ──
  if exists (
    select 1 from public.transactions
    where reference_transaction_id = p_transaction_id
  ) then
    raise exception 'Cannot delete transaction that has settlement references. Delete settlements first.';
  end if;

  -- ── Delete (cascade removes items, triggers fire for balance + budget) ──
  delete from public.transactions
  where id = p_transaction_id and user_id = v_user_id;

  return jsonb_build_object(
    'transaction_id', p_transaction_id,
    'deleted', true
  );
end;
$$;


-- ════════════════════════════════════════════════════════════════════════════
-- RPC 4: create_adjustment_transaction
-- ════════════════════════════════════════════════════════════════════════════
-- Adjustment: mengoreksi saldo wallet ke nilai target.
-- Karena total_amount harus > 0, kita hitung selisih dan tentukan arah:
--   Jika target > current → income-like (adjustment adds)
--   Jika target < current → expense-like, but still type='adjustment'
--
-- Approach: Kita selalu buat type='adjustment' dengan total_amount = abs(selisih).
-- Trigger interprets adjustment as ALWAYS adding. Untuk pengurangan, kita
-- perlu special handling di trigger.
--
-- REVISED: Karena PRD bilang adjustment "+/- sesuai selisih", dan constraint
-- total_amount > 0, kita buat 2 approach:
--   - positive adjustment (target > current): total_amount = diff
--   - negative adjustment (target < current): kita set note='negative_adjustment'
--     dan trigger akan mengurangi.
-- SIMPLER APPROACH: Kita pakai signed approach di trigger — tapi constraint
-- memaksa total_amount > 0. Solusi: kita store absolute value, dan tambah
-- field direction via note convention.
--
-- FINAL APPROACH: Buat RPC yang menghitung diff, lalu buat transaksi
-- expense (untuk pengurangan) atau income (untuk penambahan) — tapi
-- dengan type 'adjustment'. Trigger menambah untuk adjustment.
-- Untuk pengurangan, kita tetap type adjustment tapi trigger harus tahu
-- direction. Simplest: kita UPDATE balance langsung di RPC karena ini
-- sudah dalam security definer, lalu buat transaction record sebagai audit.
--
-- SAFEST (per PRD): kita biarkan trigger handle, tapi kita perlu trik.
-- Kita set total_amount = abs(diff) dan simpan diff sign di note.
-- Trigger: adjustment selalu ADD total_amount, jadi untuk negative adjustment
-- kita perlu inverse. Let's make the trigger smarter — NO, trigger already
-- deployed.
--
-- DECISION: RPC calculates diff. If negative adjustment needed:
-- - Create two steps in one TX: first update balance directly, then insert
--   adjustment record with trigger disabled... too complex.
--
-- PRAGMATIC: adjustment total_amount stores ABSOLUTE diff. We add a
-- convention field. But we can't add fields not in spec.
-- 
-- SIMPLEST VALID: We handle it by:
-- 1. Calculate diff = target - current_balance
-- 2. If diff > 0: insert adjustment (trigger ADDS, correct!)
-- 3. If diff < 0: insert adjustment with total_amount = abs(diff)
--    BUT trigger would ADD, which is WRONG for negative diff.
--
-- FIX: Update the trigger to handle adjustment differently based on
-- a transient signal. OR: simpler, just do the balance update in the RPC
-- atomically and insert the transaction record with trigger temporarily
-- disabled for that row... too complex.
--
-- REAL FIX: The RPC directly manages wallet balance + transaction insert
-- while skipping the trigger for adjustment type. We'll disable/enable
-- the trigger within the TX. This is safe because we're in security definer.
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.create_adjustment_transaction(
  p_wallet_id       uuid,
  p_target_balance  numeric,
  p_date            timestamptz default now(),
  p_note            text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_balance numeric;
  v_diff numeric;
  v_txn_id uuid;
  v_system_cat_id uuid;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- ── Get current balance ──
  select balance into v_current_balance
  from public.wallets
  where id = p_wallet_id and user_id = v_user_id;

  if v_current_balance is null then
    raise exception 'Wallet not found or not owned by user';
  end if;

  v_diff := p_target_balance - v_current_balance;

  if v_diff = 0 then
    return jsonb_build_object('adjusted', false, 'reason', 'No difference');
  end if;

  -- ── Temporarily disable wallet balance trigger ──
  -- We manage balance manually for adjustment because trigger always ADDs
  -- but adjustment can be negative.
  alter table public.transactions disable trigger trg_update_wallet_balance;

  -- ── Insert adjustment transaction (total_amount = abs diff per constraint) ──
  insert into public.transactions (
    user_id, wallet_id, type, total_amount, date, note
  ) values (
    v_user_id, p_wallet_id, 'adjustment', abs(v_diff), p_date,
    coalesce(p_note, 'Penyesuaian saldo')
  )
  returning id into v_txn_id;

  -- ── Find system category for adjustment ──
  select id into v_system_cat_id
  from public.categories
  where type = 'system' and name = 'Penyesuaian Saldo' and user_id = v_user_id
  limit 1;

  -- Fallback: try global system category
  if v_system_cat_id is null then
    select id into v_system_cat_id
    from public.categories
    where type = 'system' and name = 'Penyesuaian Saldo' and user_id is null
    limit 1;
  end if;

  -- ── Insert single item ──
  insert into public.transaction_items (
    transaction_id, category_id, item_name, amount, note
  ) values (
    v_txn_id, v_system_cat_id, 'Penyesuaian Saldo', abs(v_diff), p_note
  );

  -- ── Directly update wallet balance ──
  update public.wallets
  set balance = p_target_balance
  where id = p_wallet_id and user_id = v_user_id;

  -- ── Re-enable trigger ──
  alter table public.transactions enable trigger trg_update_wallet_balance;

  return jsonb_build_object(
    'transaction_id', v_txn_id,
    'adjusted', true,
    'previous_balance', v_current_balance,
    'new_balance', p_target_balance,
    'diff', v_diff
  );

exception
  when others then
    -- Ensure trigger is re-enabled even on error
    alter table public.transactions enable trigger trg_update_wallet_balance;
    raise;
end;
$$;


-- ════════════════════════════════════════════════════════════════════════════
-- RPC 5: settle_debt_or_loan
-- ════════════════════════════════════════════════════════════════════════════
-- Pelunasan hutang/piutang.
--   debt_payment:     type=expense, settlement_kind=debt_payment → uang keluar wallet
--   loan_collection:  type=income, settlement_kind=loan_collection → uang masuk wallet
-- Reference ke transaksi asal (debt/loan).
-- Update status di transaksi asal jika lunas.
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.settle_debt_or_loan(
  p_reference_transaction_id  uuid,
  p_settlement_kind           text,   -- 'debt_payment' or 'loan_collection'
  p_amount                    numeric,
  p_wallet_id                 uuid,
  p_date                      timestamptz default now(),
  p_note                      text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_ref_txn record;
  v_type text;
  v_txn_id uuid;
  v_total_settled numeric;
  v_new_status text;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- ── Validate settlement_kind ──
  if p_settlement_kind not in ('debt_payment', 'loan_collection') then
    raise exception 'Invalid settlement_kind: %', p_settlement_kind;
  end if;

  -- ── Determine transaction type from settlement kind ──
  v_type := case p_settlement_kind
    when 'debt_payment' then 'expense'
    when 'loan_collection' then 'income'
  end;

  -- ── Validate reference transaction ──
  select * into v_ref_txn
  from public.transactions
  where id = p_reference_transaction_id and user_id = v_user_id;

  if v_ref_txn is null then
    raise exception 'Reference transaction not found';
  end if;

  -- debt_payment harus refer ke debt, loan_collection ke loan
  if p_settlement_kind = 'debt_payment' and v_ref_txn.type != 'debt' then
    raise exception 'debt_payment can only reference a debt transaction';
  end if;
  if p_settlement_kind = 'loan_collection' and v_ref_txn.type != 'loan' then
    raise exception 'loan_collection can only reference a loan transaction';
  end if;

  -- ── Validate amount > 0 ──
  if p_amount <= 0 then
    raise exception 'Settlement amount must be positive';
  end if;

  -- ── Guard: total settlement cannot exceed original principal ──
  select coalesce(sum(total_amount), 0) into v_total_settled
  from public.transactions
  where reference_transaction_id = p_reference_transaction_id
    and settlement_kind = p_settlement_kind;

  if (v_total_settled + p_amount) > v_ref_txn.total_amount then
    raise exception 'Settlement total (%) would exceed original principal (%)',
      v_total_settled + p_amount, v_ref_txn.total_amount;
  end if;

  -- ── Validate wallet ownership ──
  if not exists (
    select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
  ) then
    raise exception 'Wallet not found or not owned by user';
  end if;

  -- ── Create settlement transaction ──
  insert into public.transactions (
    user_id, wallet_id, type, total_amount, date, note,
    with_person, reference_transaction_id, settlement_kind
  ) values (
    v_user_id, p_wallet_id, v_type, p_amount, p_date, p_note,
    v_ref_txn.with_person, p_reference_transaction_id, p_settlement_kind
  )
  returning id into v_txn_id;

  -- ── Insert single item ──
  insert into public.transaction_items (
    transaction_id, item_name, amount, note
  ) values (
    v_txn_id,
    case p_settlement_kind
      when 'debt_payment' then 'Pelunasan Hutang'
      when 'loan_collection' then 'Penagihan Piutang'
    end,
    p_amount,
    p_note
  );

  -- ── Update status on reference transaction ──
  v_total_settled := v_total_settled + p_amount;
  v_new_status := case
    when v_total_settled >= v_ref_txn.total_amount then 'paid'
    when v_total_settled > 0 then 'partial'
    else 'unpaid'
  end;

  update public.transactions
  set status = v_new_status
  where id = p_reference_transaction_id and user_id = v_user_id;

  return jsonb_build_object(
    'settlement_transaction_id', v_txn_id,
    'reference_transaction_id', p_reference_transaction_id,
    'settlement_kind', p_settlement_kind,
    'amount', p_amount,
    'total_settled', v_total_settled,
    'original_amount', v_ref_txn.total_amount,
    'new_status', v_new_status
  );
end;
$$;


-- ════════════════════════════════════════════════════════════════════════════
-- RPC 6: create_investment_with_optional_wallet_deduction
-- ════════════════════════════════════════════════════════════════════════════
-- Jika user mencentang "Potong dari Wallet":
--   1. Create investment record
--   2. Create transfer_to_asset transaction → wallet balance berkurang via trigger
-- Jika tidak:
--   1. Create investment record only (no wallet impact)
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.create_investment_with_optional_wallet_deduction(
  p_type                  text,         -- gold, crypto, custom
  p_name                  text,
  p_amount                numeric,      -- jumlah unit
  p_avg_buy_price         numeric,      -- harga beli per unit
  p_symbol                text default null,
  p_custom_current_price  numeric default null,
  p_linked_wallet_id      uuid default null,
  p_deduct_from_wallet    boolean default false,
  p_notes                 text default null,
  p_date                  timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_inv_id uuid;
  v_txn_id uuid;
  v_total_cost numeric;
  v_system_cat_id uuid;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  v_total_cost := p_amount * p_avg_buy_price;

  -- ── Create investment record ──
  insert into public.investments (
    user_id, type, name, symbol, amount, avg_buy_price,
    custom_current_price, linked_wallet_id, notes
  ) values (
    v_user_id, p_type, p_name, p_symbol, p_amount, p_avg_buy_price,
    p_custom_current_price, p_linked_wallet_id, p_notes
  )
  returning id into v_inv_id;

  -- ── If deduct from wallet, create transfer_to_asset transaction ──
  if p_deduct_from_wallet and p_linked_wallet_id is not null then
    -- Validate wallet ownership
    if not exists (
      select 1 from public.wallets where id = p_linked_wallet_id and user_id = v_user_id
    ) then
      raise exception 'Linked wallet not found or not owned by user';
    end if;

    -- Find system category for transfer-to-asset
    select id into v_system_cat_id
    from public.categories
    where type = 'system' and name = 'Transfer ke Aset' and user_id = v_user_id
    limit 1;

    if v_system_cat_id is null then
      select id into v_system_cat_id
      from public.categories
      where type = 'system' and name = 'Transfer ke Aset' and user_id is null
      limit 1;
    end if;

    -- Create transfer_to_asset transaction (trigger deducts wallet balance)
    insert into public.transactions (
      user_id, wallet_id, type, total_amount, date,
      note, merchant_name
    ) values (
      v_user_id, p_linked_wallet_id, 'transfer_to_asset', v_total_cost,
      p_date, p_notes, p_name
    )
    returning id into v_txn_id;

    -- Insert item
    insert into public.transaction_items (
      transaction_id, category_id, item_name, amount, note
    ) values (
      v_txn_id, v_system_cat_id,
      'Pembelian ' || p_name,
      v_total_cost,
      p_notes
    );
  end if;

  return jsonb_build_object(
    'investment_id', v_inv_id,
    'transaction_id', v_txn_id,
    'deducted_from_wallet', (p_deduct_from_wallet and p_linked_wallet_id is not null),
    'total_cost', v_total_cost
  );
end;
$$;
