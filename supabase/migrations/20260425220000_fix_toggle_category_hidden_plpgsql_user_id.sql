-- Memperbaiki 42702: "user_id" ambigu di PL/pgSQL (variabel output RETURNS TABLE vs kolom).
-- Sama isi dengan yang diterapkan lewat Supabase (lihat 20260425092826 bila perlu).
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
