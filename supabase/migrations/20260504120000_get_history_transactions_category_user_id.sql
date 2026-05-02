-- Sertakan categories.user_id di JSON hasil get_history_transactions agar app bisa
-- membedakan katalog global vs kategori milik user untuk pelokalan nama tampilan.

DO $$
DECLARE
  v_sql text;
BEGIN
  SELECT replace(
    pg_get_functiondef(p.oid),
    '''background_color'', c.background_color)',
    '''background_color'', c.background_color, ''user_id'', c.user_id)'
  )
  INTO v_sql
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname = 'get_history_transactions';

  IF v_sql IS NULL OR position('user_id' IN v_sql) = 0 THEN
    RAISE EXCEPTION 'get_history_transactions: patch user_id gagal atau fungsi tidak ada';
  END IF;

  EXECUTE v_sql;
END
$$;
