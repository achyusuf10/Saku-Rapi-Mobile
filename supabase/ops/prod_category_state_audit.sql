-- Baca saja. Jalankan di Supabase → SQL (production) sebelum/ setelah migrasi kategori
-- agar state DB prod terlihat (bandingkan dengan rencana migrasi).
SELECT
  (SELECT count(*)::int FROM public.categories WHERE user_id IS NULL) AS categories_global,
  (SELECT count(*)::int
   FROM public.categories
   WHERE user_id IS NOT NULL AND is_default) AS categories_per_user_default,
  (SELECT count(*)::int
   FROM public.categories
   WHERE user_id IS NOT NULL AND NOT is_default) AS categories_custom;
SELECT to_regclass('public.user_category_hidden') IS NOT NULL AS has_user_category_hidden;
SELECT to_regclass('public.parsing_dictionaries') IS NOT NULL AS has_parsing_dictionaries;
SELECT EXISTS (
  SELECT 1
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'categories' AND column_name = 'is_hidden'
) AS categories_has_is_hidden_column;
SELECT
  t.tgname
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
WHERE c.relname = 'categories' AND NOT t.tgisinternal
ORDER BY t.tgname;
