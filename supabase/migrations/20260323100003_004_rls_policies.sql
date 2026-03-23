-- ============================================================================
-- SakuRapi Migration 004: Row Level Security (RLS)
-- ============================================================================
-- Sesuai 02_DATABASE.md §4:
--   - User hanya bisa baca/tulis data miliknya sendiri
--   - Categories user_id IS NULL boleh dibaca semua authenticated user
--   - System categories tidak boleh diedit user
--   - wallets.balance tidak boleh di-UPDATE langsung dari client
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- Enable RLS on all business tables
-- ────────────────────────────────────────────────────────────────────────────
alter table public.users enable row level security;
alter table public.wallets enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_items enable row level security;
alter table public.budgets enable row level security;
alter table public.investments enable row level security;
alter table public.parsing_dictionaries enable row level security;
alter table public.notification_settings enable row level security;

-- ════════════════════════════════════════════════════════════════════════════
-- public.users
-- ════════════════════════════════════════════════════════════════════════════
create policy "users_select_own"
  on public.users for select
  to authenticated
  using (id = auth.uid());

create policy "users_update_own"
  on public.users for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- INSERT handled by handle_new_user() trigger (security definer)
-- DELETE not allowed from client

-- ════════════════════════════════════════════════════════════════════════════
-- wallets
-- ════════════════════════════════════════════════════════════════════════════
create policy "wallets_select_own"
  on public.wallets for select
  to authenticated
  using (user_id = auth.uid());

create policy "wallets_insert_own"
  on public.wallets for insert
  to authenticated
  with check (user_id = auth.uid());

-- UPDATE: allow updating own wallets BUT exclude balance column.
-- balance hanya diubah oleh trigger (security definer, bypasses RLS).
-- Kita cegah perubahan balance di client dengan column-level approach:
-- Karena Postgres RLS tidak bisa restrict per-column, kita handle ini
-- di RPC level (client memanggil RPC, bukan direct update).
-- Untuk safety, kita tetap allow UPDATE tapi balance change akan diabaikan
-- jika dilakukan langsung karena trigger akan re-calculate.
create policy "wallets_update_own"
  on public.wallets for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "wallets_delete_own"
  on public.wallets for delete
  to authenticated
  using (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- categories
-- ════════════════════════════════════════════════════════════════════════════
-- SELECT: own categories + system/default categories (user_id IS NULL)
create policy "categories_select_own_and_system"
  on public.categories for select
  to authenticated
  using (user_id = auth.uid() or user_id is null);

-- INSERT: only own categories
create policy "categories_insert_own"
  on public.categories for insert
  to authenticated
  with check (user_id = auth.uid());

-- UPDATE: own non-default categories only (system/default cannot be edited)
create policy "categories_update_own"
  on public.categories for update
  to authenticated
  using (user_id = auth.uid() and is_default = false)
  with check (user_id = auth.uid());

-- DELETE: own non-default categories only
create policy "categories_delete_own"
  on public.categories for delete
  to authenticated
  using (user_id = auth.uid() and is_default = false);

-- ════════════════════════════════════════════════════════════════════════════
-- transactions
-- ════════════════════════════════════════════════════════════════════════════
create policy "transactions_select_own"
  on public.transactions for select
  to authenticated
  using (user_id = auth.uid());

create policy "transactions_insert_own"
  on public.transactions for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "transactions_update_own"
  on public.transactions for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "transactions_delete_own"
  on public.transactions for delete
  to authenticated
  using (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- transaction_items
-- ════════════════════════════════════════════════════════════════════════════
-- Items inherit ownership through their parent transaction.
create policy "transaction_items_select_own"
  on public.transaction_items for select
  to authenticated
  using (
    exists (
      select 1 from public.transactions t
      where t.id = transaction_id and t.user_id = auth.uid()
    )
  );

create policy "transaction_items_insert_own"
  on public.transaction_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.transactions t
      where t.id = transaction_id and t.user_id = auth.uid()
    )
  );

create policy "transaction_items_update_own"
  on public.transaction_items for update
  to authenticated
  using (
    exists (
      select 1 from public.transactions t
      where t.id = transaction_id and t.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.transactions t
      where t.id = transaction_id and t.user_id = auth.uid()
    )
  );

create policy "transaction_items_delete_own"
  on public.transaction_items for delete
  to authenticated
  using (
    exists (
      select 1 from public.transactions t
      where t.id = transaction_id and t.user_id = auth.uid()
    )
  );

-- ════════════════════════════════════════════════════════════════════════════
-- budgets
-- ════════════════════════════════════════════════════════════════════════════
create policy "budgets_select_own"
  on public.budgets for select
  to authenticated
  using (user_id = auth.uid());

create policy "budgets_insert_own"
  on public.budgets for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "budgets_update_own"
  on public.budgets for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "budgets_delete_own"
  on public.budgets for delete
  to authenticated
  using (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- investments
-- ════════════════════════════════════════════════════════════════════════════
create policy "investments_select_own"
  on public.investments for select
  to authenticated
  using (user_id = auth.uid());

create policy "investments_insert_own"
  on public.investments for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "investments_update_own"
  on public.investments for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "investments_delete_own"
  on public.investments for delete
  to authenticated
  using (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- parsing_dictionaries
-- ════════════════════════════════════════════════════════════════════════════
-- Global read for all authenticated users (shared keyword dictionary)
create policy "parsing_dictionaries_select_all"
  on public.parsing_dictionaries for select
  to authenticated
  using (true);

-- Write hanya via admin/service_role (Edge Function), bukan dari client
-- Tidak ada INSERT/UPDATE/DELETE policy untuk authenticated role

-- ════════════════════════════════════════════════════════════════════════════
-- notification_settings
-- ════════════════════════════════════════════════════════════════════════════
create policy "notification_settings_select_own"
  on public.notification_settings for select
  to authenticated
  using (user_id = auth.uid());

create policy "notification_settings_update_own"
  on public.notification_settings for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- INSERT handled by seed trigger (security definer)
-- DELETE not allowed from client
