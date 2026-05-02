-- Default icon background: translucent gray (#32C4C4C4 = ~19% alpha on #C4C4C4).

ALTER TABLE public.categories
  ALTER COLUMN background_color SET DEFAULT '#32C4C4C4';

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'wallets'
      AND column_name = 'background_color'
  ) THEN
    ALTER TABLE public.wallets
      ALTER COLUMN background_color SET DEFAULT '#32C4C4C4';
  END IF;
END
$$;
