-- Bagian 1/3: seed katalog global bila belum ada, tabel peta, map parent+child, validasi
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
END $$;
