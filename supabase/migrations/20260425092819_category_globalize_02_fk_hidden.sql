-- Bagian 2/3: remap FK, sembunyi, dedupe, unik, backfill hidden untuk custom
UPDATE public.transaction_items t
SET category_id = m.new_id
FROM public._category_migration_remap m
WHERE t.category_id = m.old_id;

UPDATE public.budgets b
SET category_id = m.new_id
FROM public._category_migration_remap m
WHERE b.category_id = m.old_id;

DO $pd$
BEGIN
  IF to_regclass('public.parsing_dictionaries') IS NOT NULL THEN
    UPDATE public.parsing_dictionaries p
    SET category_id = m.new_id
    FROM public._category_migration_remap m
    WHERE p.category_id = m.old_id;
  END IF;
END
$pd$;

UPDATE public.user_category_hidden h
SET category_id = m.new_id
FROM public._category_migration_remap m
WHERE h.category_id = m.old_id;

DELETE FROM public.user_category_hidden a
  USING public.user_category_hidden b
  WHERE a.ctid < b.ctid
    AND a.user_id = b.user_id
    AND a.category_id = b.category_id;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_category_hidden_user_id_category_id_key'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'user_category_hidden_user_id_category_id_key'
  ) THEN
    BEGIN
      ALTER TABLE public.user_category_hidden
        ADD CONSTRAINT user_category_hidden_user_id_category_id_key UNIQUE (user_id, category_id);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Tidak bisa membuat unique user_category_hidden: %, sqlstate %', SQLERRM, SQLSTATE;
    END;
  END IF;
END $$;

INSERT INTO public.user_category_hidden (user_id, category_id)
SELECT c.user_id, c.id
FROM public.categories c
WHERE c.user_id IS NOT NULL
  AND c.is_default = false
  AND c.is_hidden = true
ON CONFLICT (user_id, category_id) DO NOTHING;
