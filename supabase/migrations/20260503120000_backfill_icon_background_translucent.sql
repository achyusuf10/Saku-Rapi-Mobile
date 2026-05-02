-- Selaraskan default + data lama dengan Flutter `kSakuDefaultIconBackgroundHex` (#32C4C4C4).
-- Memperbarui baris yang masih memakai abu opaque lama (#C4C4C4) atau dompet lama (#E5E7EB).

ALTER TABLE public.categories
  ALTER COLUMN background_color SET DEFAULT '#32C4C4C4';

UPDATE public.categories
SET background_color = '#32C4C4C4'
WHERE replace(lower(trim(background_color)), '#', '') IN ('c4c4c4');

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

    UPDATE public.wallets
    SET background_color = '#32C4C4C4'
    WHERE replace(lower(trim(background_color)), '#', '')
      IN ('c4c4c4', 'e5e7eb');
  END IF;
END
$$;
