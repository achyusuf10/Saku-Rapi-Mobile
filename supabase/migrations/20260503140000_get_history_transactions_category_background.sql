-- Sertakan categories.background_color di JSON hasil get_history_transactions
-- agar TransactionItemModel.categoryBackgroundColor terisi (Riwayat / History).

DO $$
DECLARE
  v_sql text;
BEGIN
  SELECT regexp_replace(
    pg_get_functiondef(p.oid),
    'jsonb_build_object\(''name'', c\.name, ''icon'', c\.icon, ''color'', c\.color\)',
    'jsonb_build_object(''name'', c.name, ''icon'', c.icon, ''color'', c.color, ''background_color'', c.background_color)',
    'g'
  )
  INTO v_sql
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname = 'get_history_transactions';

  IF v_sql IS NULL OR position('background_color' in v_sql) = 0 THEN
    RAISE EXCEPTION 'get_history_transactions: patch gagal atau fungsi tidak ada';
  END IF;

  EXECUTE v_sql;
END
$$;
