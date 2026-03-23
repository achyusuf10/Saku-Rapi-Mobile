-- ============================================================================
-- SakuRapi Migration 001: Base Schema
-- ============================================================================
-- Membuat semua tabel utama sesuai 02_DATABASE.md §2.
-- Ledger rule: wallets.balance HANYA berubah dari trigger pada transactions.
-- MVP: IDR only, single currency.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 2.1 public.users (mirror auth.users)
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.users is 'Mirror of auth.users for public profile data';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.2 wallets
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.wallets (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.users(id) on delete cascade,
  name                text not null,
  icon                text not null,
  color               text not null,
  balance             numeric not null default 0,
  initial_balance     numeric not null default 0,
  currency            text not null default 'IDR',
  exclude_from_total  boolean not null default false,
  sort_order          integer not null default 0,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  -- Constraints per 02_DATABASE.md §2.2
  constraint wallets_currency_idr check (currency = 'IDR'),
  constraint wallets_initial_balance_non_negative check (initial_balance >= 0),
  constraint wallets_unique_name_per_user unique (user_id, name)
);

comment on table public.wallets is 'User wallets. Balance hanya diubah via trigger dari transactions';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.3 categories (parent-child max 2 level)
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.users(id) on delete cascade,  -- null = system/global
  name        text not null,
  icon        text not null,
  color       text not null,
  type        text not null,
  parent_id   uuid references public.categories(id) on delete cascade,
  is_default  boolean not null default false,
  is_hidden   boolean not null default false,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  -- Category type harus salah satu dari income, expense, system
  constraint categories_type_check check (type in ('income', 'expense', 'system'))
);

comment on table public.categories is 'Transaction categories with parent-child hierarchy (max 2 level)';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.4 transactions (ledger utama)
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.transactions (
  id                          uuid primary key default gen_random_uuid(),
  user_id                     uuid not null references public.users(id) on delete cascade,
  wallet_id                   uuid not null references public.wallets(id) on delete restrict,
  destination_wallet_id       uuid references public.wallets(id) on delete restrict,
  type                        text not null,
  total_amount                numeric not null,
  date                        timestamptz not null,
  merchant_name               text,
  note                        text,
  attachment_url              text,
  with_person                 text,
  status                      text,
  due_date                    timestamptz,
  is_multi_item               boolean not null default false,
  reference_transaction_id    uuid references public.transactions(id) on delete set null,
  settlement_kind             text,
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),

  -- Type enum
  constraint transactions_type_check check (
    type in ('income', 'expense', 'transfer', 'debt', 'loan', 'adjustment', 'transfer_to_asset')
  ),
  -- Amount harus positif
  constraint transactions_total_amount_positive check (total_amount > 0),
  -- Transfer: destination_wallet_id wajib dan tidak boleh sama dengan wallet_id
  constraint transactions_transfer_dest_required check (
    type != 'transfer' or destination_wallet_id is not null
  ),
  constraint transactions_no_self_transfer check (
    wallet_id != destination_wallet_id
  ),
  -- Debt/loan: with_person wajib
  constraint transactions_debt_loan_person check (
    type not in ('debt', 'loan') or with_person is not null
  ),
  -- Status enum untuk debt/loan
  constraint transactions_status_check check (
    status is null or status in ('unpaid', 'paid', 'partial')
  ),
  -- Settlement kind enum
  constraint transactions_settlement_kind_check check (
    settlement_kind is null or settlement_kind in ('debt_payment', 'loan_collection')
  ),
  -- Settlement harus punya reference
  constraint transactions_settlement_reference check (
    settlement_kind is null or reference_transaction_id is not null
  ),
  -- debt_payment harus type expense
  constraint transactions_debt_payment_type check (
    settlement_kind != 'debt_payment' or type = 'expense'
  ),
  -- loan_collection harus type income
  constraint transactions_loan_collection_type check (
    settlement_kind != 'loan_collection' or type = 'income'
  )
);

comment on table public.transactions is 'Ledger utama. Setiap mutasi saldo wallet HARUS melalui tabel ini';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.5 transaction_items
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.transaction_items (
  id              uuid primary key default gen_random_uuid(),
  transaction_id  uuid not null references public.transactions(id) on delete cascade,
  category_id     uuid references public.categories(id) on delete set null,
  item_name       text,
  qty             numeric not null default 1,
  unit_price      numeric,
  amount          numeric not null,
  note            text,
  sort_order      integer not null default 0,

  -- Amount harus positif
  constraint transaction_items_amount_positive check (amount > 0),
  -- Qty harus positif
  constraint transaction_items_qty_positive check (qty > 0)
);

comment on table public.transaction_items is 'Detail item per transaksi. Minimal 1 row per transaction';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.6 budgets
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.budgets (
  id                      uuid primary key default gen_random_uuid(),
  user_id                 uuid not null references public.users(id) on delete cascade,
  category_id             uuid not null references public.categories(id) on delete cascade,
  wallet_id               uuid references public.wallets(id) on delete cascade,  -- null = global
  amount                  numeric not null,
  used_amount             numeric not null default 0,
  start_date              date not null,
  end_date                date not null,
  is_recurring            boolean not null default false,
  notification_sent_80    boolean not null default false,
  notification_sent_100   boolean not null default false,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  -- Budget amount harus positif
  constraint budgets_amount_positive check (amount > 0),
  -- end >= start
  constraint budgets_date_range check (end_date >= start_date)
);

comment on table public.budgets is 'Budget hanya untuk expense categories, non-settlement';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.7 investments
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.investments (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references public.users(id) on delete cascade,
  type                  text not null,
  name                  text not null,
  symbol                text,
  amount                numeric not null,
  avg_buy_price         numeric not null,
  custom_current_price  numeric,
  linked_wallet_id      uuid references public.wallets(id) on delete set null,
  notes                 text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),

  -- Investment type enum
  constraint investments_type_check check (type in ('gold', 'crypto', 'custom')),
  -- Amount harus positif
  constraint investments_amount_positive check (amount > 0),
  -- Avg buy price harus positif
  constraint investments_avg_buy_price_positive check (avg_buy_price > 0)
);

comment on table public.investments is 'Portfolio investasi. Deduction wallet via transfer_to_asset di ledger';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.8 parsing_dictionaries
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.parsing_dictionaries (
  id          uuid primary key default gen_random_uuid(),
  keyword     text not null,
  category_id uuid not null references public.categories(id) on delete cascade,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  -- Keyword harus lowercase dan unique
  constraint parsing_dictionaries_keyword_lower check (keyword = lower(keyword)),
  constraint parsing_dictionaries_keyword_unique unique (keyword)
);

comment on table public.parsing_dictionaries is 'AI parser keyword-to-category mapping. Cache 24h di client';

-- ────────────────────────────────────────────────────────────────────────────
-- 2.9 notification_settings
-- ────────────────────────────────────────────────────────────────────────────
create table if not exists public.notification_settings (
  id                          uuid primary key default gen_random_uuid(),
  user_id                     uuid not null references public.users(id) on delete cascade,
  reminder_enabled            boolean not null default false,
  reminder_time               time,
  budget_alert_enabled        boolean not null default true,
  debt_reminder_enabled       boolean not null default true,
  debt_reminder_days_before   integer not null default 3,
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),

  -- Satu setting per user
  constraint notification_settings_unique_user unique (user_id)
);

comment on table public.notification_settings is 'Per-user notification preferences';
