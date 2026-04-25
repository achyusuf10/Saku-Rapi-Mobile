-- MIGRASI KATEGORI — PRODUCTION (geehwokpxfqldssozqvq)
-- Prasyarat: backup. Jalankan prod_category_state_audit.sql dulu.
-- Hanya SQL (tanpa perintah psql). Boleh satu transaksi: BEGIN; … COMMIT; di sekitar seluruh skrip bila mau.
-- Isi: noop v1, 01 seed+remap, 02 fk+hidden, 03 rpc+cleanup, lalu 25220000 = CREATE OR REPLACE toggle (idempoten dengan 03).

SELECT 0;

-- ========== 20260425092813: 01 seed_remap ==========
DROP FUNCTION IF EXISTS public.get_user_categories();
DROP FUNCTION IF EXISTS public.get_user_categories(text);
DROP FUNCTION IF EXISTS public.toggle_category_hidden(uuid, boolean);

DO $$
DECLARE
  n_global int;
  canon_user uuid;
  r record;
  v_new_id uuid;
  v_new_parent uuid;
BEGIN
  SELECT count(*)::int
  INTO n_global
  FROM public.categories
  WHERE user_id IS NULL;
  IF n_global > 0 THEN
    RAISE NOTICE
      'category global seed: lewati (sudah ada % kategori user_id null)',
      n_global;
    RETURN;
  END IF;

  SELECT c.user_id
  INTO canon_user
  FROM public.categories c
  WHERE c.is_default = true
    AND c.user_id IS NOT NULL
  GROUP BY c.user_id
  ORDER BY count(*)::int DESC, c.user_id
  LIMIT 1;

  IF canon_user IS NULL THEN
    RAISE EXCEPTION
      'category global seed: tidak ada bawaan per user (is_default) untuk sumber katalog'
      USING ERRCODE = 'object_not_in_prerequisite_state';
  END IF;

  EXECUTE 'CREATE TEMP TABLE _canon_to_global (old_id uuid PRIMARY KEY, new_id uuid NOT NULL)';

  FOR r IN
  WITH RECURSIVE t AS (
    SELECT
      c.id, c.parent_id, c.name, c.icon, c.color, c.type, c.is_default, c.sort_order, c.is_hidden,
      0 AS depth
    FROM public.categories c
    WHERE
      c.user_id = canon_user
      AND c.is_default = true
      AND c.parent_id IS NULL
    UNION ALL
    SELECT
      c2.id, c2.parent_id, c2.name, c2.icon, c2.color, c2.type, c2.is_default, c2.sort_order, c2.is_hidden,
      t.depth + 1
    FROM public.categories c2
    JOIN t ON c2.parent_id = t.id
    WHERE
      c2.user_id = canon_user
      AND c2.is_default = true
  )
  SELECT *
  FROM t
  ORDER BY depth, sort_order, name
  LOOP
    IF r.parent_id IS NULL THEN
      v_new_parent := NULL;
    ELSE
      EXECUTE
        'SELECT m.new_id FROM _canon_to_global m WHERE m.old_id = $1'
        INTO v_new_parent
        USING r.parent_id;
      IF v_new_parent IS NULL THEN
        RAISE EXCEPTION 'category global seed: parent % belum ada di peta untuk anak %', r.parent_id, r.id;
      END IF;
    END IF;

    INSERT INTO public.categories (
      id, user_id, name, icon, color, type, parent_id, is_default, is_hidden, sort_order, created_at, updated_at
    )
    VALUES (
      gen_random_uuid(),
      NULL,
      r.name, r.icon, r.color, r.type, v_new_parent, true, false, r.sort_order, now(), now()
    )
    RETURNING id
    INTO v_new_id;

    EXECUTE
      'INSERT INTO _canon_to_global (old_id, new_id) VALUES ($1, $2)'
      USING r.id, v_new_id;
  END LOOP;

  EXECUTE 'DROP TABLE IF EXISTS _canon_to_global';
END
$$;

CREATE TABLE IF NOT EXISTS public._category_migration_remap (
  old_id uuid NOT NULL PRIMARY KEY,
  new_id uuid NOT NULL REFERENCES public.categories (id) ON UPDATE CASCADE
);
TRUNCATE public._category_migration_remap;

INSERT INTO public._category_migration_remap (old_id, new_id)
SELECT d.id, g.id
FROM public.categories d
JOIN public.categories g
  ON g.user_id IS NULL
  AND d.type = g.type
  AND d.parent_id IS NULL
  AND g.parent_id IS NULL
  AND lower(btrim(d.name)) = lower(btrim(g.name))
WHERE d.is_default = true
  AND d.user_id IS NOT NULL
  AND d.parent_id IS NULL
ON CONFLICT (old_id) DO NOTHING;

INSERT INTO public._category_migration_remap (old_id, new_id)
SELECT d.id, g.id
FROM public.categories d
JOIN public._category_migration_remap pm ON d.parent_id = pm.old_id
JOIN public.categories g
  ON g.user_id IS NULL
  AND g.type = d.type
  AND g.parent_id = pm.new_id
  AND lower(btrim(d.name)) = lower(btrim(g.name))
WHERE d.is_default = true
  AND d.user_id IS NOT NULL
  AND d.parent_id IS NOT NULL
ON CONFLICT (old_id) DO NOTHING;

DO $$
DECLARE
  n int;
BEGIN
  SELECT count(*)::int
  INTO n
  FROM public.categories d
  WHERE d.is_default = true
    AND d.user_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM public._category_migration_remap m WHERE m.old_id = d.id);

  IF n > 0 THEN
    RAISE EXCEPTION
      'category migration: % user default rows not mapped to global; periksa nama, tipe, parent, atau isi tabel peta manual',
      n
      USING ERRCODE = 'check_violation';
  END IF;
END
$$;

-- ========== 20260425092819: 02 fk_hidden ==========
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

-- ========== 20260425092826: 03 cleanup_rpc ==========
DELETE FROM public.categories
WHERE id IN (SELECT old_id FROM public._category_migration_remap);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'categories'
      AND column_name = 'is_hidden'
  ) THEN
    ALTER TABLE public.categories DROP COLUMN is_hidden;
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.get_user_categories (p_type text default null)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  name text,
  icon text,
  color text,
  type text,
  parent_id uuid,
  is_default boolean,
  sort_order integer,
  created_at timestamptz,
  updated_at timestamptz,
  is_hidden boolean
)
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.id,
    c.user_id,
    c.name,
    c.icon,
    c.color,
    c.type::text,
    c.parent_id,
    c.is_default,
    c.sort_order,
    c.created_at,
    c.updated_at,
    (EXISTS (
      SELECT 1
      FROM public.user_category_hidden h
      WHERE h.user_id = auth.uid()
        AND h.category_id = c.id
    )) AS is_hidden
  FROM public.categories c
  WHERE (c.user_id IS NULL OR c.user_id = auth.uid())
    AND (p_type IS NULL OR c.type::text = p_type)
  ORDER BY c.sort_order, c.name
$$;

GRANT EXECUTE ON FUNCTION public.get_user_categories (text) TO authenticated;

CREATE OR REPLACE FUNCTION public.toggle_category_hidden (
  p_category_id uuid,
  p_is_hidden boolean
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  name text,
  icon text,
  color text,
  type text,
  parent_id uuid,
  is_default boolean,
  sort_order integer,
  created_at timestamptz,
  updated_at timestamptz,
  is_hidden boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = 'P0001';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.categories c0
    WHERE c0.id = p_category_id
      AND (c0.user_id IS NULL OR c0.user_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'Category not found or forbidden' USING ERRCODE = 'P0001';
  END IF;

  IF p_is_hidden THEN
    INSERT INTO public.user_category_hidden
    VALUES (v_uid, p_category_id)
    ON CONFLICT ON CONSTRAINT user_category_hidden_user_id_category_id_key
    DO NOTHING;
  ELSE
    DELETE FROM public.user_category_hidden uch
    WHERE uch.user_id = v_uid AND uch.category_id = p_category_id;
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.user_id,
    c.name,
    c.icon,
    c.color,
    c.type::text,
    c.parent_id,
    c.is_default,
    c.sort_order,
    c.created_at,
    c.updated_at,
    (EXISTS (
      SELECT 1
      FROM public.user_category_hidden uhh
      WHERE uhh.user_id = v_uid AND uhh.category_id = c.id
    ))::boolean
  FROM public.categories c
  WHERE c.id = p_category_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_category_hidden (uuid, boolean) TO authenticated;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT
      t.tgname,
      n.nspname,
      c.relname
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE t.tgname = 'trg_seed_default_categories'
      AND NOT t.tgisinternal
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', r.tgname, r.nspname, r.relname);
  END LOOP;
END
$$;

CREATE OR REPLACE FUNCTION public.seed_default_categories ()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN new;
END;
$$;

DROP TABLE IF EXISTS public._category_migration_remap;

-- ========== 20260425220000: perkuat toggle (sama isi, idempoten) ==========
CREATE OR REPLACE FUNCTION public.toggle_category_hidden (
  p_category_id uuid,
  p_is_hidden boolean
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  name text,
  icon text,
  color text,
  type text,
  parent_id uuid,
  is_default boolean,
  sort_order integer,
  created_at timestamptz,
  updated_at timestamptz,
  is_hidden boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = 'P0001';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.categories c0
    WHERE c0.id = p_category_id
      AND (c0.user_id IS NULL OR c0.user_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'Category not found or forbidden' USING ERRCODE = 'P0001';
  END IF;

  IF p_is_hidden THEN
    INSERT INTO public.user_category_hidden
    VALUES (v_uid, p_category_id)
    ON CONFLICT ON CONSTRAINT user_category_hidden_user_id_category_id_key
    DO NOTHING;
  ELSE
    DELETE FROM public.user_category_hidden uch
    WHERE uch.user_id = v_uid AND uch.category_id = p_category_id;
  END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.user_id,
    c.name,
    c.icon,
    c.color,
    c.type::text,
    c.parent_id,
    c.is_default,
    c.sort_order,
    c.created_at,
    c.updated_at,
    (EXISTS (
      SELECT 1
      FROM public.user_category_hidden uhh
      WHERE uhh.user_id = v_uid AND uhh.category_id = c.id
    ))::boolean
  FROM public.categories c
  WHERE c.id = p_category_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_category_hidden (uuid, boolean) TO authenticated;
