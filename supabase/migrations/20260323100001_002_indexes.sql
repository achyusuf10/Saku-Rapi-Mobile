-- ============================================================================
-- SakuRapi Migration 002: Indexes
-- ============================================================================
-- Index sesuai 02_DATABASE.md §5.
-- Optimasi query untuk dashboard, history, budget, dan report.
-- ============================================================================

-- ─── wallets ────────────────────────────────────────────────────────────────
create index if not exists idx_wallets_user_sort
  on public.wallets (user_id, sort_order);

-- ─── categories ─────────────────────────────────────────────────────────────
create index if not exists idx_categories_user_type_parent
  on public.categories (user_id, type, parent_id);

-- ─── transactions ───────────────────────────────────────────────────────────
-- History: filter by user + date range (descending for recent first)
create index if not exists idx_transactions_user_date
  on public.transactions (user_id, date desc);

-- Dashboard/wallet detail: filter by wallet + date
create index if not exists idx_transactions_wallet_date
  on public.transactions (wallet_id, date desc);

-- Settlement reference lookup
create index if not exists idx_transactions_reference
  on public.transactions (reference_transaction_id)
  where reference_transaction_id is not null;

-- Report/budget query: filter non-settlement expense by user + type + date
create index if not exists idx_transactions_user_type_date
  on public.transactions (user_id, type, date desc);

-- ─── transaction_items ──────────────────────────────────────────────────────
create index if not exists idx_transaction_items_txn_sort
  on public.transaction_items (transaction_id, sort_order);

-- Budget usage: lookup items by category within date range
create index if not exists idx_transaction_items_category
  on public.transaction_items (category_id)
  where category_id is not null;

-- ─── budgets ────────────────────────────────────────────────────────────────
create index if not exists idx_budgets_user_dates
  on public.budgets (user_id, start_date, end_date);

-- Budget lookup by category (for recalc trigger)
create index if not exists idx_budgets_category
  on public.budgets (category_id);

-- ─── investments ────────────────────────────────────────────────────────────
create index if not exists idx_investments_user
  on public.investments (user_id);

-- ─── parsing_dictionaries ───────────────────────────────────────────────────
create index if not exists idx_parsing_dictionaries_keyword
  on public.parsing_dictionaries (keyword);
