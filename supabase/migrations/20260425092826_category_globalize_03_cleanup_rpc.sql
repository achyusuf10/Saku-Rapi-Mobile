-- Bagian 3/3: hapus salinan, drop is_hidden, RPC, trigger, drop peta
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
END $$;

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

-- v_uid + INSERT VALUES / ON CONFLICT constraint + DELETE ter-alias: hindari
-- ambiguitas nama [user_id] (OUTPUT RETURNS TABLE) vs kolom tabel.
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
END $$;

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
