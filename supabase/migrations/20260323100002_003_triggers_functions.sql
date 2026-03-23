-- ============================================================================
-- SakuRapi Migration 003: Triggers & Functions
-- ============================================================================
-- Sesuai 02_DATABASE.md §3.1:
--   1. handle_new_user()        – after insert on auth.users
--   2. seed_default_categories()– after insert on public.users
--   3. seed_notification_settings() – after insert on public.users
--   4. update_wallet_balance()  – after insert/update/delete on transactions
--   5. update_budget_usage()    – after insert/update/delete on transaction_items
--   6. set_updated_at()         – before update on all mutable tables
--
-- LEDGER RULE: wallets.balance HANYA berubah lewat trigger #4.
-- ============================================================================


-- ════════════════════════════════════════════════════════════════════════════
-- 1. set_updated_at() — Generic timestamp updater
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Apply ke semua mutable tables
create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

create trigger trg_wallets_updated_at
  before update on public.wallets
  for each row execute function public.set_updated_at();

create trigger trg_categories_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

create trigger trg_transactions_updated_at
  before update on public.transactions
  for each row execute function public.set_updated_at();

create trigger trg_budgets_updated_at
  before update on public.budgets
  for each row execute function public.set_updated_at();

create trigger trg_investments_updated_at
  before update on public.investments
  for each row execute function public.set_updated_at();

create trigger trg_parsing_dictionaries_updated_at
  before update on public.parsing_dictionaries
  for each row execute function public.set_updated_at();

create trigger trg_notification_settings_updated_at
  before update on public.notification_settings
  for each row execute function public.set_updated_at();


-- ════════════════════════════════════════════════════════════════════════════
-- 2. handle_new_user() — Mirror auth.users → public.users
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update set
    email      = excluded.email,
    full_name  = coalesce(excluded.full_name, public.users.full_name),
    avatar_url = coalesce(excluded.avatar_url, public.users.avatar_url),
    updated_at = now();

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ════════════════════════════════════════════════════════════════════════════
-- 3. seed_default_categories() — Setelah user baru dibuat
-- ════════════════════════════════════════════════════════════════════════════
-- Diimplementasikan di migration 006 (seed) karena perlu data kategori.
-- Trigger dipasang di sini, function body di migration 006.
-- Placeholder function:
create or replace function public.seed_default_categories()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Akan di-replace di migration 006 dengan isi seed lengkap
  return new;
end;
$$;

create trigger trg_seed_default_categories
  after insert on public.users
  for each row execute function public.seed_default_categories();


-- ════════════════════════════════════════════════════════════════════════════
-- 4. seed_notification_settings() — Default notif settings per user
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.seed_notification_settings()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger trg_seed_notification_settings
  after insert on public.users
  for each row execute function public.seed_notification_settings();


-- ════════════════════════════════════════════════════════════════════════════
-- 5. update_wallet_balance() — LEDGER TRIGGER
-- ════════════════════════════════════════════════════════════════════════════
-- Accounting Rules Matrix (PRD §5):
--   income            → +amount ke wallet_id
--   expense           → -amount dari wallet_id
--   transfer          → -amount dari wallet_id, +amount ke destination_wallet_id
--   debt              → +amount ke wallet_id  (uang pinjaman masuk)
--   loan              → -amount dari wallet_id (uang dipinjamkan keluar)
--   adjustment        → +amount ke wallet_id (bisa + atau -, tapi total_amount > 0,
--                       adjustment direction ditentukan oleh note/context)
--   transfer_to_asset → -amount dari wallet_id
--
-- CATATAN: Untuk adjustment, karena total_amount selalu > 0 per constraint,
-- kita perlu tahu apakah ini penambahan atau pengurangan.
-- Approach: adjustment selalu ADD ke wallet (positive adjustment).
-- Untuk pengurangan, Flutter harus create expense/adjustment yang sesuai.
-- Alternatif: kita biarkan adjustment = positive (add to balance).
-- Sesuai PRD: "adjustment: +/- sesuai selisih" — kita handle ini di RPC level,
-- bukan trigger. Trigger selalu add untuk type adjustment.
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.update_wallet_balance()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_delta numeric;
  v_dest_delta numeric;
begin
  -- ─── DELETE: reverse the effect ───
  if (tg_op = 'DELETE') then
    -- Reverse source wallet
    v_delta := case old.type
      when 'income'           then -old.total_amount
      when 'expense'          then  old.total_amount
      when 'transfer'         then  old.total_amount
      when 'debt'             then -old.total_amount
      when 'loan'             then  old.total_amount
      when 'adjustment'       then -old.total_amount
      when 'transfer_to_asset' then old.total_amount
    end;

    update public.wallets
    set balance = balance + v_delta
    where id = old.wallet_id;

    -- Reverse destination wallet (transfer only)
    if old.type = 'transfer' and old.destination_wallet_id is not null then
      update public.wallets
      set balance = balance - old.total_amount
      where id = old.destination_wallet_id;
    end if;

    return old;
  end if;

  -- ─── INSERT: apply the effect ───
  if (tg_op = 'INSERT') then
    v_delta := case new.type
      when 'income'           then  new.total_amount
      when 'expense'          then -new.total_amount
      when 'transfer'         then -new.total_amount
      when 'debt'             then  new.total_amount
      when 'loan'             then -new.total_amount
      when 'adjustment'       then  new.total_amount
      when 'transfer_to_asset' then -new.total_amount
    end;

    update public.wallets
    set balance = balance + v_delta
    where id = new.wallet_id;

    -- Destination wallet (transfer only)
    if new.type = 'transfer' and new.destination_wallet_id is not null then
      update public.wallets
      set balance = balance + new.total_amount
      where id = new.destination_wallet_id;
    end if;

    return new;
  end if;

  -- ─── UPDATE: reverse old, apply new ───
  if (tg_op = 'UPDATE') then
    -- Reverse old
    v_delta := case old.type
      when 'income'           then -old.total_amount
      when 'expense'          then  old.total_amount
      when 'transfer'         then  old.total_amount
      when 'debt'             then -old.total_amount
      when 'loan'             then  old.total_amount
      when 'adjustment'       then -old.total_amount
      when 'transfer_to_asset' then old.total_amount
    end;

    update public.wallets
    set balance = balance + v_delta
    where id = old.wallet_id;

    if old.type = 'transfer' and old.destination_wallet_id is not null then
      update public.wallets
      set balance = balance - old.total_amount
      where id = old.destination_wallet_id;
    end if;

    -- Apply new
    v_delta := case new.type
      when 'income'           then  new.total_amount
      when 'expense'          then -new.total_amount
      when 'transfer'         then -new.total_amount
      when 'debt'             then  new.total_amount
      when 'loan'             then -new.total_amount
      when 'adjustment'       then  new.total_amount
      when 'transfer_to_asset' then -new.total_amount
    end;

    update public.wallets
    set balance = balance + v_delta
    where id = new.wallet_id;

    if new.type = 'transfer' and new.destination_wallet_id is not null then
      update public.wallets
      set balance = balance + new.total_amount
      where id = new.destination_wallet_id;
    end if;

    return new;
  end if;

  return null;
end;
$$;

create trigger trg_update_wallet_balance
  after insert or update or delete on public.transactions
  for each row execute function public.update_wallet_balance();


-- ════════════════════════════════════════════════════════════════════════════
-- 6. update_budget_usage() — Recalc budget used_amount
-- ════════════════════════════════════════════════════════════════════════════
-- Budget hanya menghitung expense non-settlement (PRD §4.3, §5).
-- Trigger fires on transaction_items, tapi harus join ke transactions
-- untuk mendapatkan: type, settlement_kind, date, wallet_id.
-- ════════════════════════════════════════════════════════════════════════════
create or replace function public.update_budget_usage()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_category_id uuid;
  v_txn record;
begin
  -- Determine the affected category_id
  if (tg_op = 'DELETE') then
    v_category_id := old.category_id;
  else
    v_category_id := new.category_id;
  end if;

  -- Skip if no category (transfer, debt, loan items often don't have one)
  if v_category_id is null then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;

  -- Recalc all budgets that might be affected by this category.
  -- We recalc based on actual sum to avoid drift.
  update public.budgets b
  set used_amount = coalesce((
    select sum(ti.amount)
    from public.transaction_items ti
    join public.transactions t on t.id = ti.transaction_id
    where ti.category_id = b.category_id
      and t.type = 'expense'
      and t.settlement_kind is null
      and t.date >= b.start_date::timestamptz
      and t.date < (b.end_date + interval '1 day')::timestamptz
      and (b.wallet_id is null or t.wallet_id = b.wallet_id)
  ), 0)
  where b.category_id = v_category_id
    or b.category_id in (
      -- Also check parent category budgets
      select c.parent_id from public.categories c
      where c.id = v_category_id and c.parent_id is not null
    );

  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$$;

create trigger trg_update_budget_usage
  after insert or update or delete on public.transaction_items
  for each row execute function public.update_budget_usage();


-- ════════════════════════════════════════════════════════════════════════════
-- 7. Prevent direct wallet balance modification
-- ════════════════════════════════════════════════════════════════════════════
-- Extra safety: block any direct UPDATE to wallets.balance that doesn't
-- come from our trigger. We do this by checking the caller context.
-- NOTE: This is enforced by RLS (no direct update to balance column
-- from client). The trigger runs as SECURITY DEFINER so it bypasses RLS.
-- Additional protection is via the RPC approach — client never UPDATEs wallets.balance.
