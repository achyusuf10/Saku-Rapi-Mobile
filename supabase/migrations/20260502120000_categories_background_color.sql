-- Category icon background + RPC return shape (get_user_categories, toggle_category_hidden).
-- Wallet: align server default for new rows with app (#32C4C4C4).

ALTER TABLE public.categories
  ADD COLUMN IF NOT EXISTS background_color text NOT NULL DEFAULT '#32C4C4C4';

COMMENT ON COLUMN public.categories.background_color IS
  'Hex fill behind category icon; 6 or 8 characters (#RRGGBB or #AARRGGBB).';

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

DROP FUNCTION IF EXISTS public.get_user_categories();
DROP FUNCTION IF EXISTS public.get_user_categories(text);
DROP FUNCTION IF EXISTS public.toggle_category_hidden(uuid, boolean);

CREATE FUNCTION public.get_user_categories (p_type text default null)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  name text,
  icon text,
  color text,
  background_color text,
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
    c.background_color,
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

CREATE FUNCTION public.toggle_category_hidden (
  p_category_id uuid,
  p_is_hidden boolean
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  name text,
  icon text,
  color text,
  background_color text,
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
    c.background_color,
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
