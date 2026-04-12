-- ============================================================================
-- Migration 021: Restore transaction timestamps
-- ============================================================================
-- Goal:
-- 1. Restore point-in-time fields to timestamptz:
--    - transactions.date
--    - investment_transactions.date
-- 2. Keep true calendar fields as DATE:
--    - transactions.due_date
-- 3. Restore RPC signatures / return types that should preserve time
-- 4. Keep budget rollups calendar-based on Jakarta business dates until
--    server-side per-user timezone metadata exists
--
-- Note:
-- Migration 019 flattened existing timestamps into calendar dates. The exact
-- original time is no longer recoverable, so existing rows are backfilled to
-- 00:00 Asia/Jakarta for their stored business date.
-- ============================================================================

begin;

drop function if exists public.create_transaction_with_items(
  uuid,
  uuid,
  text,
  numeric,
  date,
  text,
  text,
  text,
  text,
  text,
  date,
  boolean,
  uuid,
  text,
  jsonb,
  uuid
);

drop function if exists public.update_transaction_with_items(
  uuid,
  uuid,
  uuid,
  text,
  numeric,
  date,
  text,
  text,
  text,
  text,
  text,
  date,
  boolean,
  uuid,
  text,
  jsonb,
  uuid
);

drop function if exists public.create_adjustment_transaction(
  uuid,
  numeric,
  date,
  text
);

drop function if exists public.settle_debt_or_loan(
  uuid,
  text,
  numeric,
  uuid,
  date,
  text
);

drop function if exists public.get_debt_loan_transactions_by_person(
  text,
  text,
  uuid
);

drop function if exists public.get_settlement_history(uuid);

drop function if exists public.create_investment_asset(
  text,
  text,
  text,
  uuid,
  uuid,
  text,
  text,
  numeric,
  numeric,
  numeric,
  numeric,
  date,
  text,
  boolean,
  uuid
);

drop function if exists public.topup_investment(
  uuid,
  numeric,
  numeric,
  numeric,
  date,
  text,
  boolean,
  uuid
);

drop function if exists public.sell_investment(
  uuid,
  numeric,
  numeric,
  date,
  text,
  boolean,
  uuid
);

drop function if exists public.edit_investment_transaction(
  uuid,
  numeric,
  numeric,
  numeric,
  date,
  text,
  boolean,
  uuid
);

alter table public.transactions
  alter column date drop default,
  alter column date type timestamptz using (date::timestamp at time zone 'Asia/Jakarta'),
  alter column date set default now();

alter table public.investment_transactions
  alter column date drop default,
  alter column date type timestamptz using (date::timestamp at time zone 'Asia/Jakarta'),
  alter column date set default now();

create or replace function public.update_budget_usage()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_category_id uuid;
begin
  if (tg_op = 'DELETE') then
    v_category_id := old.category_id;
  else
    v_category_id := new.category_id;
  end if;

  if v_category_id is null then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  update public.budgets b
  set used_amount = coalesce((
    select sum(ti.amount)
    from public.transaction_items ti
    join public.transactions t on t.id = ti.transaction_id
    where (
      ti.category_id = b.category_id
      or ti.category_id in (
        select c.id
        from public.categories c
        where c.parent_id = b.category_id
      )
    )
      and t.type = 'expense'
      and t.settlement_kind is null
      and (t.date at time zone 'Asia/Jakarta')::date between b.start_date and b.end_date
      and (b.wallet_id is null or t.wallet_id = b.wallet_id)
  ), 0)
  where b.category_id = v_category_id
    or b.category_id in (
      select c.parent_id
      from public.categories c
      where c.id = v_category_id and c.parent_id is not null
    );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$function$;

create function public.create_transaction_with_items(
  p_wallet_id uuid,
  p_destination_wallet_id uuid default null,
  p_type text default 'expense',
  p_total_amount numeric default 0,
  p_date timestamptz default now(),
  p_merchant_name text default null,
  p_note text default null,
  p_attachment_url text default null,
  p_with_person text default null,
  p_status text default null,
  p_due_date date default null,
  p_is_multi_item boolean default false,
  p_reference_transaction_id uuid default null,
  p_settlement_kind text default null,
  p_items jsonb default '[]'::jsonb,
  p_contact_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
  v_txn_id uuid;
  v_item jsonb;
  v_items_sum numeric := 0;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

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

  if not exists (
    select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
  ) then
    raise exception 'Wallet not found or not owned by user';
  end if;

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

  insert into public.transactions (
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
  ) values (
    v_user_id,
    p_wallet_id,
    p_destination_wallet_id,
    p_type,
    p_total_amount,
    p_date,
    p_merchant_name,
    p_note,
    p_attachment_url,
    p_with_person,
    p_status,
    p_due_date,
    p_is_multi_item,
    p_reference_transaction_id,
    p_settlement_kind,
    p_contact_id
  )
  returning id into v_txn_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.transaction_items (
      transaction_id,
      category_id,
      item_name,
      qty,
      unit_price,
      amount,
      note,
      sort_order
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

  select jsonb_build_object(
    'transaction_id', v_txn_id,
    'wallet_id', p_wallet_id,
    'type', p_type,
    'total_amount', p_total_amount,
    'items_count', jsonb_array_length(p_items)
  ) into v_result;

  return v_result;
end;
$function$;

create function public.update_transaction_with_items(
  p_transaction_id uuid,
  p_wallet_id uuid,
  p_destination_wallet_id uuid default null,
  p_type text default 'expense',
  p_total_amount numeric default 0,
  p_date timestamptz default now(),
  p_merchant_name text default null,
  p_note text default null,
  p_attachment_url text default null,
  p_with_person text default null,
  p_status text default null,
  p_due_date date default null,
  p_is_multi_item boolean default false,
  p_reference_transaction_id uuid default null,
  p_settlement_kind text default null,
  p_items jsonb default '[]'::jsonb,
  p_contact_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
  v_item jsonb;
  v_items_sum numeric := 0;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.transactions
    where id = p_transaction_id and user_id = v_user_id
  ) then
    raise exception 'Transaction not found or not owned by user';
  end if;

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

  if not exists (
    select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
  ) then
    raise exception 'Wallet not found or not owned by user';
  end if;

  if p_type = 'transfer' then
    if p_destination_wallet_id is null then
      raise exception 'Transfer requires destination_wallet_id';
    end if;
    if p_wallet_id = p_destination_wallet_id then
      raise exception 'Cannot transfer to the same wallet';
    end if;
  end if;

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

  delete from public.transaction_items
  where transaction_id = p_transaction_id;

  update public.transactions
  set wallet_id = p_wallet_id,
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
      settlement_kind = p_settlement_kind,
      contact_id = p_contact_id
  where id = p_transaction_id and user_id = v_user_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    insert into public.transaction_items (
      transaction_id,
      category_id,
      item_name,
      qty,
      unit_price,
      amount,
      note,
      sort_order
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
$function$;

create function public.create_adjustment_transaction(
  p_wallet_id uuid,
  p_target_balance numeric,
  p_date timestamptz default now(),
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
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

  alter table public.transactions disable trigger trg_update_wallet_balance;

  insert into public.transactions (
    user_id,
    wallet_id,
    type,
    total_amount,
    date,
    note
  ) values (
    v_user_id,
    p_wallet_id,
    'adjustment',
    abs(v_diff),
    p_date,
    coalesce(p_note, 'Penyesuaian saldo')
  )
  returning id into v_txn_id;

  select id into v_system_cat_id
  from public.categories
  where type = 'system' and name = 'Penyesuaian Saldo' and user_id = v_user_id
  limit 1;

  if v_system_cat_id is null then
    select id into v_system_cat_id
    from public.categories
    where type = 'system' and name = 'Penyesuaian Saldo' and user_id is null
    limit 1;
  end if;

  insert into public.transaction_items (
    transaction_id,
    category_id,
    item_name,
    amount,
    note
  ) values (
    v_txn_id,
    v_system_cat_id,
    'Penyesuaian Saldo',
    abs(v_diff),
    p_note
  );

  update public.wallets
  set balance = p_target_balance
  where id = p_wallet_id and user_id = v_user_id;

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
    alter table public.transactions enable trigger trg_update_wallet_balance;
    raise;
end;
$function$;

create function public.settle_debt_or_loan(
  p_reference_transaction_id uuid,
  p_settlement_kind text,
  p_amount numeric,
  p_wallet_id uuid,
  p_date timestamptz default now(),
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
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

  if p_settlement_kind not in ('debt_payment', 'loan_collection') then
    raise exception 'Invalid settlement_kind: %', p_settlement_kind;
  end if;

  v_type := case p_settlement_kind
    when 'debt_payment' then 'expense'
    when 'loan_collection' then 'income'
  end;

  select * into v_ref_txn
  from public.transactions
  where id = p_reference_transaction_id and user_id = v_user_id;

  if v_ref_txn is null then
    raise exception 'Reference transaction not found';
  end if;

  if p_settlement_kind = 'debt_payment' and v_ref_txn.type != 'debt' then
    raise exception 'debt_payment can only reference a debt transaction';
  end if;
  if p_settlement_kind = 'loan_collection' and v_ref_txn.type != 'loan' then
    raise exception 'loan_collection can only reference a loan transaction';
  end if;

  if p_amount <= 0 then
    raise exception 'Settlement amount must be positive';
  end if;

  select coalesce(sum(total_amount), 0) into v_total_settled
  from public.transactions
  where reference_transaction_id = p_reference_transaction_id
    and settlement_kind = p_settlement_kind;

  if (v_total_settled + p_amount) > v_ref_txn.total_amount then
    raise exception 'Settlement total (%) would exceed original principal (%)',
      v_total_settled + p_amount, v_ref_txn.total_amount;
  end if;

  if not exists (
    select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
  ) then
    raise exception 'Wallet not found or not owned by user';
  end if;

  insert into public.transactions (
    user_id,
    wallet_id,
    type,
    total_amount,
    date,
    note,
    with_person,
    reference_transaction_id,
    settlement_kind
  ) values (
    v_user_id,
    p_wallet_id,
    v_type,
    p_amount,
    p_date,
    p_note,
    v_ref_txn.with_person,
    p_reference_transaction_id,
    p_settlement_kind
  )
  returning id into v_txn_id;

  insert into public.transaction_items (
    transaction_id,
    item_name,
    amount,
    note
  ) values (
    v_txn_id,
    case p_settlement_kind
      when 'debt_payment' then 'Pelunasan Hutang'
      when 'loan_collection' then 'Penagihan Piutang'
    end,
    p_amount,
    p_note
  );

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
$function$;

create function public.get_debt_loan_transactions_by_person(
  p_with_person text,
  p_type text,
  p_wallet_id uuid default null
)
returns table(
  id uuid,
  wallet_id uuid,
  wallet_name text,
  type text,
  total_amount numeric,
  date timestamptz,
  note text,
  with_person text,
  contact_id uuid,
  status text,
  due_date date,
  settlement_kind text,
  reference_transaction_id uuid,
  total_settled numeric,
  remaining numeric,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  return query
  select
    t.id,
    t.wallet_id,
    w.name as wallet_name,
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
    coalesce((
      select sum(s.total_amount)
      from public.transactions s
      where s.reference_transaction_id = t.id
        and s.settlement_kind is not null
        and s.user_id = v_user_id
    ), 0)::numeric as total_settled,
    (t.total_amount - coalesce((
      select sum(s.total_amount)
      from public.transactions s
      where s.reference_transaction_id = t.id
        and s.settlement_kind is not null
        and s.user_id = v_user_id
    ), 0))::numeric as remaining,
    t.created_at
  from public.transactions t
  join public.wallets w on w.id = t.wallet_id
  where t.user_id = v_user_id
    and t.with_person is not distinct from p_with_person
    and t.type = p_type
    and t.settlement_kind is null
    and (p_wallet_id is null or t.wallet_id = p_wallet_id)
  order by t.date desc, t.created_at desc;
end;
$function$;

create function public.get_settlement_history(
  p_reference_transaction_id uuid
)
returns table(
  id uuid,
  wallet_id uuid,
  wallet_name text,
  type text,
  total_amount numeric,
  date timestamptz,
  note text,
  with_person text,
  settlement_kind text,
  reference_transaction_id uuid,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1 from public.transactions t
    where t.id = p_reference_transaction_id and t.user_id = v_user_id
  ) then
    raise exception 'Reference transaction not found';
  end if;

  return query
  select
    t.id,
    t.wallet_id,
    w.name as wallet_name,
    t.type::text,
    t.total_amount::numeric,
    t.date,
    t.note,
    t.with_person,
    t.settlement_kind::text,
    t.reference_transaction_id,
    t.created_at
  from public.transactions t
  join public.wallets w on w.id = t.wallet_id
  where t.user_id = v_user_id
    and t.reference_transaction_id = p_reference_transaction_id
    and t.settlement_kind is not null
  order by t.date desc, t.created_at desc;
end;
$function$;

create function public.create_investment_asset(
  p_type text,
  p_name text,
  p_gold_type text default null,
  p_custom_gold_type_id uuid default null,
  p_custom_category_id uuid default null,
  p_unit_label text default 'unit',
  p_price_source text default 'manual',
  p_current_price numeric default 0,
  p_units numeric default 0,
  p_price_per_unit numeric default 0,
  p_fee numeric default 0,
  p_date timestamptz default now(),
  p_note text default null,
  p_deduct_wallet boolean default false,
  p_wallet_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
  v_asset_id uuid;
  v_tx_id uuid;
  v_wallet_tx_id uuid := null;
  v_total_cost numeric;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_units <= 0 then
    raise exception 'Units must be greater than 0';
  end if;

  if p_price_per_unit < 0 then
    raise exception 'Price per unit must not be negative';
  end if;

  v_total_cost := (p_units * p_price_per_unit) + p_fee;

  if p_deduct_wallet and p_wallet_id is not null then
    if not exists (
      select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
    ) then
      raise exception 'Wallet not found or not owned by user';
    end if;
  end if;

  insert into public.investment_assets (
    user_id,
    type,
    name,
    gold_type,
    custom_gold_type_id,
    custom_category_id,
    unit_label,
    price_source,
    current_price
  ) values (
    v_user_id,
    p_type,
    p_name,
    p_gold_type,
    p_custom_gold_type_id,
    p_custom_category_id,
    p_unit_label,
    p_price_source,
    p_current_price
  )
  returning id into v_asset_id;

  if p_deduct_wallet and p_wallet_id is not null then
    insert into public.transactions (
      user_id,
      wallet_id,
      type,
      total_amount,
      date,
      note,
      is_multi_item
    ) values (
      v_user_id,
      p_wallet_id,
      'transfer_to_asset',
      v_total_cost,
      p_date,
      'Investment: ' || p_name,
      false
    )
    returning id into v_wallet_tx_id;

    insert into public.transaction_items (
      transaction_id,
      item_name,
      qty,
      amount,
      sort_order
    ) values (
      v_wallet_tx_id,
      'Investment: ' || p_name,
      1,
      v_total_cost,
      0
    );
  end if;

  insert into public.investment_transactions (
    asset_id,
    user_id,
    direction,
    units,
    price_per_unit,
    fee,
    wallet_id,
    deduct_wallet,
    linked_wallet_transaction_id,
    date,
    note
  ) values (
    v_asset_id,
    v_user_id,
    'buy',
    p_units,
    p_price_per_unit,
    p_fee,
    p_wallet_id,
    p_deduct_wallet,
    v_wallet_tx_id,
    p_date,
    p_note
  )
  returning id into v_tx_id;

  select jsonb_build_object(
    'asset', to_jsonb(a),
    'transaction', to_jsonb(t)
  ) into v_result
  from public.investment_assets a,
       public.investment_transactions t
  where a.id = v_asset_id and t.id = v_tx_id;

  return v_result;
end;
$function$;

create function public.topup_investment(
  p_asset_id uuid,
  p_units numeric,
  p_price_per_unit numeric,
  p_fee numeric default 0,
  p_date timestamptz default now(),
  p_note text default null,
  p_deduct_wallet boolean default false,
  p_wallet_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
  v_asset record;
  v_tx_id uuid;
  v_wallet_tx_id uuid := null;
  v_total_cost numeric;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_units <= 0 then
    raise exception 'Units must be greater than 0';
  end if;

  select * into v_asset
  from public.investment_assets
  where id = p_asset_id and user_id = v_user_id;

  if not found then
    raise exception 'Asset not found or not owned by user';
  end if;

  v_total_cost := (p_units * p_price_per_unit) + p_fee;

  if p_deduct_wallet and p_wallet_id is not null then
    if not exists (
      select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
    ) then
      raise exception 'Wallet not found or not owned by user';
    end if;
  end if;

  if p_deduct_wallet and p_wallet_id is not null then
    insert into public.transactions (
      user_id,
      wallet_id,
      type,
      total_amount,
      date,
      note,
      is_multi_item
    ) values (
      v_user_id,
      p_wallet_id,
      'transfer_to_asset',
      v_total_cost,
      p_date,
      'Top Up: ' || v_asset.name,
      false
    )
    returning id into v_wallet_tx_id;

    insert into public.transaction_items (
      transaction_id,
      item_name,
      qty,
      amount,
      sort_order
    ) values (
      v_wallet_tx_id,
      'Top Up: ' || v_asset.name,
      1,
      v_total_cost,
      0
    );
  end if;

  insert into public.investment_transactions (
    asset_id,
    user_id,
    direction,
    units,
    price_per_unit,
    fee,
    wallet_id,
    deduct_wallet,
    linked_wallet_transaction_id,
    date,
    note
  ) values (
    p_asset_id,
    v_user_id,
    'buy',
    p_units,
    p_price_per_unit,
    p_fee,
    p_wallet_id,
    p_deduct_wallet,
    v_wallet_tx_id,
    p_date,
    p_note
  )
  returning id into v_tx_id;

  if not v_asset.is_active then
    update public.investment_assets
    set is_active = true
    where id = p_asset_id;
  end if;

  select to_jsonb(t) into strict v_result
  from public.investment_transactions t
  where t.id = v_tx_id;

  return v_result;
end;
$function$;

create function public.sell_investment(
  p_asset_id uuid,
  p_units numeric,
  p_price_per_unit numeric,
  p_date timestamptz default now(),
  p_note text default null,
  p_credit_wallet boolean default false,
  p_wallet_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
  v_asset record;
  v_total_buy_units numeric;
  v_total_sell_units numeric;
  v_remaining numeric;
  v_tx_id uuid;
  v_wallet_tx_id uuid := null;
  v_proceeds numeric;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_units <= 0 then
    raise exception 'Units must be greater than 0';
  end if;

  select * into v_asset
  from public.investment_assets
  where id = p_asset_id and user_id = v_user_id;

  if not found then
    raise exception 'Asset not found or not owned by user';
  end if;

  select
    coalesce(sum(case when direction = 'buy' then units else 0 end), 0),
    coalesce(sum(case when direction = 'sell' then units else 0 end), 0)
  into v_total_buy_units, v_total_sell_units
  from public.investment_transactions
  where asset_id = p_asset_id;

  v_remaining := v_total_buy_units - v_total_sell_units;

  if p_units > v_remaining then
    raise exception 'Insufficient units. Available: %, Requested: %', v_remaining, p_units;
  end if;

  v_proceeds := p_units * p_price_per_unit;

  if p_credit_wallet and p_wallet_id is not null then
    if not exists (
      select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
    ) then
      raise exception 'Wallet not found or not owned by user';
    end if;

    insert into public.transactions (
      user_id,
      wallet_id,
      type,
      total_amount,
      date,
      note,
      is_multi_item
    ) values (
      v_user_id,
      p_wallet_id,
      'income',
      v_proceeds,
      p_date,
      'Sell: ' || v_asset.name,
      false
    )
    returning id into v_wallet_tx_id;

    insert into public.transaction_items (
      transaction_id,
      item_name,
      qty,
      amount,
      sort_order
    ) values (
      v_wallet_tx_id,
      'Sell: ' || v_asset.name,
      1,
      v_proceeds,
      0
    );
  end if;

  insert into public.investment_transactions (
    asset_id,
    user_id,
    direction,
    units,
    price_per_unit,
    fee,
    wallet_id,
    deduct_wallet,
    linked_wallet_transaction_id,
    date,
    note
  ) values (
    p_asset_id,
    v_user_id,
    'sell',
    p_units,
    p_price_per_unit,
    0,
    p_wallet_id,
    p_credit_wallet,
    v_wallet_tx_id,
    p_date,
    p_note
  )
  returning id into v_tx_id;

  if (v_remaining - p_units) = 0 then
    update public.investment_assets
    set is_active = false
    where id = p_asset_id;
  end if;

  v_result := jsonb_build_object(
    'transaction_id', v_tx_id,
    'remaining_units', v_remaining - p_units,
    'is_active', (v_remaining - p_units) > 0,
    'proceeds', v_proceeds,
    'wallet_credited', p_credit_wallet
  );

  return v_result;
end;
$function$;

create function public.edit_investment_transaction(
  p_transaction_id uuid,
  p_units numeric,
  p_price_per_unit numeric,
  p_fee numeric default 0,
  p_date timestamptz default now(),
  p_note text default null,
  p_deduct_wallet boolean default false,
  p_wallet_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
  v_old_tx record;
  v_asset_id uuid;
  v_total_buy_units numeric;
  v_total_sell_units numeric;
  v_new_buy_total numeric;
  v_wallet_tx_id uuid := null;
  v_total_cost numeric;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_units <= 0 then
    raise exception 'Units must be greater than 0';
  end if;

  select * into v_old_tx
  from public.investment_transactions
  where id = p_transaction_id and user_id = v_user_id;

  if not found then
    raise exception 'Transaction not found or not owned by user';
  end if;

  if v_old_tx.direction != 'buy' then
    raise exception 'Only buy transactions can be edited';
  end if;

  v_asset_id := v_old_tx.asset_id;

  select
    coalesce(sum(case when direction = 'buy' then units else 0 end), 0),
    coalesce(sum(case when direction = 'sell' then units else 0 end), 0)
  into v_total_buy_units, v_total_sell_units
  from public.investment_transactions
  where asset_id = v_asset_id;

  v_new_buy_total := v_total_buy_units - v_old_tx.units + p_units;

  if v_new_buy_total < v_total_sell_units then
    raise exception 'Edit rejected. Asset units cannot go below sold units. Current sell total: %', v_total_sell_units;
  end if;

  if v_old_tx.linked_wallet_transaction_id is not null then
    delete from public.transaction_items
    where transaction_id = v_old_tx.linked_wallet_transaction_id;

    delete from public.transactions
    where id = v_old_tx.linked_wallet_transaction_id;
  end if;

  v_total_cost := (p_units * p_price_per_unit) + p_fee;

  if p_deduct_wallet and p_wallet_id is not null then
    if not exists (
      select 1 from public.wallets where id = p_wallet_id and user_id = v_user_id
    ) then
      raise exception 'Wallet not found or not owned by user';
    end if;

    insert into public.transactions (
      user_id,
      wallet_id,
      type,
      total_amount,
      date,
      note,
      is_multi_item
    ) values (
      v_user_id,
      p_wallet_id,
      'transfer_to_asset',
      v_total_cost,
      p_date,
      'Edit Investment Buy',
      false
    )
    returning id into v_wallet_tx_id;

    insert into public.transaction_items (
      transaction_id,
      item_name,
      qty,
      amount,
      sort_order
    ) values (
      v_wallet_tx_id,
      'Edit Investment Buy',
      1,
      v_total_cost,
      0
    );
  end if;

  update public.investment_transactions
  set units = p_units,
      price_per_unit = p_price_per_unit,
      fee = p_fee,
      date = p_date,
      note = p_note,
      wallet_id = p_wallet_id,
      deduct_wallet = p_deduct_wallet,
      linked_wallet_transaction_id = v_wallet_tx_id
  where id = p_transaction_id;

  v_new_buy_total := v_total_buy_units - v_old_tx.units + p_units;
  if (v_new_buy_total - v_total_sell_units) > 0 then
    update public.investment_assets
    set is_active = true
    where id = v_asset_id and not is_active;
  else
    update public.investment_assets
    set is_active = false
    where id = v_asset_id and is_active;
  end if;

  return jsonb_build_object(
    'transaction_id', p_transaction_id,
    'updated', true,
    'remaining_units', v_new_buy_total - v_total_sell_units
  );
end;
$function$;

commit;
