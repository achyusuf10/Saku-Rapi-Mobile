-- ════════════════════════════════════════════════════════════════════════════
-- 008: Asset Types table + update investments FK
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Create asset_types table
create table if not exists public.asset_types (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.users(id) on delete cascade,
  name              text not null,
  symbol            text,
  current_price     numeric not null default 0,
  is_deleted        boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint asset_types_current_price_non_negative check (current_price >= 0)
);

comment on table public.asset_types is 'Jenis aset kustom yang dibuat user untuk investasi custom. Soft delete via is_deleted.';

-- 2. Add asset_type_id FK to investments
alter table public.investments
  add column if not exists asset_type_id uuid references public.asset_types(id) on delete set null;

-- 3. Indexes
create index if not exists idx_asset_types_user_id on public.asset_types(user_id);
create index if not exists idx_asset_types_user_active on public.asset_types(user_id) where is_deleted = false;
create index if not exists idx_investments_asset_type_id on public.investments(asset_type_id);

-- 4. updated_at trigger
create trigger trg_asset_types_updated_at
  before update on public.asset_types
  for each row execute function public.set_updated_at();

-- 5. RLS policies
alter table public.asset_types enable row level security;

create policy "asset_types_select_own"
  on public.asset_types for select using (auth.uid() = user_id);

create policy "asset_types_insert_own"
  on public.asset_types for insert with check (auth.uid() = user_id);

create policy "asset_types_update_own"
  on public.asset_types for update
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "asset_types_delete_own"
  on public.asset_types for delete using (auth.uid() = user_id);

-- 6. Update RPC to support asset_type_id
create or replace function public.create_investment_with_optional_wallet_deduction(
  p_type                  text,
  p_name                  text,
  p_amount                numeric,
  p_avg_buy_price         numeric,
  p_symbol                text default null,
  p_custom_current_price  numeric default null,
  p_linked_wallet_id      uuid default null,
  p_deduct_from_wallet    boolean default false,
  p_notes                 text default null,
  p_date                  timestamptz default now(),
  p_asset_type_id         uuid default null
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

  insert into public.investments (
    user_id, type, name, symbol, amount, avg_buy_price,
    custom_current_price, linked_wallet_id, notes, asset_type_id
  ) values (
    v_user_id, p_type, p_name, p_symbol, p_amount, p_avg_buy_price,
    p_custom_current_price, p_linked_wallet_id, p_notes, p_asset_type_id
  )
  returning id into v_inv_id;

  if p_deduct_from_wallet and p_linked_wallet_id is not null then
    if not exists (
      select 1 from public.wallets where id = p_linked_wallet_id and user_id = v_user_id
    ) then
      raise exception 'Linked wallet not found or not owned by user';
    end if;

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

    insert into public.transactions (
      user_id, wallet_id, type, total_amount, date,
      note, merchant_name
    ) values (
      v_user_id, p_linked_wallet_id, 'transfer_to_asset', v_total_cost,
      p_date, p_notes, p_name
    )
    returning id into v_txn_id;

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
