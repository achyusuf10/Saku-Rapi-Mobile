-- ============================================================================
-- Migration 011: Investment Tables
-- Applied via Supabase MCP in previous session
-- ============================================================================
-- Tables created:
--   1. custom_gold_types     (max 2 per user, trigger enforced)
--   2. custom_asset_categories (max 3 per user, trigger enforced)
--   3. investment_assets     (master, FK to gold types & categories)
--   4. investment_transactions (buy/sell rows, CASCADE from assets)
--   5. gold_prices           (source CHECK: antaremas/logammulia)
--   6. bitcoin_prices        (source UNIQUE for UPSERT)
--
-- NOTE: This migration was already applied to live Supabase.
--       This file is kept for local reference/documentation only.
-- ============================================================================

-- ─── 1. custom_gold_types ───
CREATE TABLE IF NOT EXISTS public.custom_gold_types (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.check_max_custom_gold_types()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT count(*) FROM public.custom_gold_types WHERE user_id = NEW.user_id) >= 2 THEN
    RAISE EXCEPTION 'Maximum 2 custom gold types per user';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_max_custom_gold_types
  BEFORE INSERT ON public.custom_gold_types
  FOR EACH ROW EXECUTE FUNCTION public.check_max_custom_gold_types();

ALTER TABLE public.custom_gold_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own custom_gold_types"
  ON public.custom_gold_types FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── 2. custom_asset_categories ───
CREATE TABLE IF NOT EXISTS public.custom_asset_categories (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       text NOT NULL,
  unit_label text NOT NULL DEFAULT 'Unit',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.check_max_custom_asset_categories()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT count(*) FROM public.custom_asset_categories WHERE user_id = NEW.user_id) >= 3 THEN
    RAISE EXCEPTION 'Maximum 3 custom asset categories per user';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_max_custom_asset_categories
  BEFORE INSERT ON public.custom_asset_categories
  FOR EACH ROW EXECUTE FUNCTION public.check_max_custom_asset_categories();

ALTER TABLE public.custom_asset_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own custom_asset_categories"
  ON public.custom_asset_categories FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── 3. investment_assets ───
CREATE TABLE IF NOT EXISTS public.investment_assets (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type                text NOT NULL CHECK (type IN ('gold', 'bitcoin', 'custom')),
  name                text NOT NULL,
  gold_type           text,
  custom_gold_type_id uuid REFERENCES public.custom_gold_types(id) ON DELETE SET NULL,
  custom_category_id  uuid REFERENCES public.custom_asset_categories(id) ON DELETE SET NULL,
  unit_label          text NOT NULL DEFAULT 'unit',
  price_source        text NOT NULL DEFAULT 'manual',
  current_price       numeric NOT NULL DEFAULT 0,
  is_active           boolean NOT NULL DEFAULT true,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_investment_assets_user ON public.investment_assets(user_id);
CREATE INDEX idx_investment_assets_type ON public.investment_assets(type);

ALTER TABLE public.investment_assets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own investment_assets"
  ON public.investment_assets FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── 4. investment_transactions ───
CREATE TABLE IF NOT EXISTS public.investment_transactions (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id                    uuid NOT NULL REFERENCES public.investment_assets(id) ON DELETE CASCADE,
  user_id                     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  direction                   text NOT NULL CHECK (direction IN ('buy', 'sell')),
  units                       numeric NOT NULL,
  price_per_unit              numeric NOT NULL,
  fee                         numeric NOT NULL DEFAULT 0,
  wallet_id                   uuid REFERENCES public.wallets(id) ON DELETE SET NULL,
  deduct_wallet               boolean NOT NULL DEFAULT false,
  linked_wallet_transaction_id uuid REFERENCES public.transactions(id) ON DELETE SET NULL,
  date                        timestamptz NOT NULL DEFAULT now(),
  note                        text,
  created_at                  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_investment_transactions_asset ON public.investment_transactions(asset_id);
CREATE INDEX idx_investment_transactions_user ON public.investment_transactions(user_id);

ALTER TABLE public.investment_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own investment_transactions"
  ON public.investment_transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── 5. gold_prices ───
CREATE TABLE IF NOT EXISTS public.gold_prices (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source     text NOT NULL CHECK (source IN ('antaremas', 'logammulia')),
  buy_price  numeric NOT NULL,
  sell_price numeric NOT NULL,
  fetched_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.gold_prices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read gold_prices"
  ON public.gold_prices FOR SELECT USING (true);

-- ─── 6. bitcoin_prices ───
CREATE TABLE IF NOT EXISTS public.bitcoin_prices (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source     text NOT NULL UNIQUE,
  price_idr  numeric NOT NULL,
  fetched_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.bitcoin_prices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read bitcoin_prices"
  ON public.bitcoin_prices FOR SELECT USING (true);

-- ─── Triggers: updated_at ───
CREATE TRIGGER trg_set_updated_at_custom_gold_types
  BEFORE UPDATE ON public.custom_gold_types
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_set_updated_at_custom_asset_categories
  BEFORE UPDATE ON public.custom_asset_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_set_updated_at_investment_assets
  BEFORE UPDATE ON public.investment_assets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
