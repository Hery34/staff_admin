# RPC Supabase: Mouvements paginés (Move-In + Move-Out)

Exécute ce script dans **Supabase SQL Editor**.

```sql
CREATE OR REPLACE FUNCTION public.get_movements_paginated(
  site_id_param bigint DEFAULT NULL,
  allowed_site_ids_param bigint[] DEFAULT NULL,
  movement_type_param text DEFAULT 'all',
  search_param text DEFAULT '',
  page_param integer DEFAULT 0,
  page_size_param integer DEFAULT 25
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_type text := lower(coalesce(movement_type_param, 'all'));
  v_search text := btrim(coalesce(search_param, ''));
  v_page integer := GREATEST(coalesce(page_param, 0), 0);
  v_size integer := GREATEST(coalesce(page_size_param, 25), 1);
  v_offset integer := GREATEST(coalesce(page_param, 0), 0) * GREATEST(coalesce(page_size_param, 25), 1);
BEGIN
  IF v_type NOT IN ('all', 'move_in', 'move_out') THEN
    v_type := 'all';
  END IF;

  RETURN (
    WITH allowed_sites AS (
      SELECT unnest(allowed_site_ids_param) AS site_id
    ),
    movement_in AS (
      SELECT
        'move_in'::text AS movement_type,
        mi.id,
        mi.created_at,
        mi.site,
        mi.name,
        mi.box,
        mi.start_date,
        mi.taille,
        mi.size_code,
        mi.id_client,
        mi.is_empty,
        mi.is_clean,
        mi.comments,
        mi.poster_ok,
        NULL::text AS leave_date,
        mi.has_loxx_on_door,
        NULL::boolean AS has_loxx,
        jsonb_build_object('id', a.id, 'firstname', a.firstname, 'lastname', a.lastname) AS created_by,
        jsonb_build_object('id', s.id, 'name', s.name, 'site_code', s.site_code) AS site_info
      FROM move_in mi
      LEFT JOIN agent a ON a.id = mi.created_by
      LEFT JOIN site s ON s.id = mi.site
      WHERE (v_type IN ('all', 'move_in'))
        AND (site_id_param IS NULL OR mi.site = site_id_param)
        AND (allowed_site_ids_param IS NULL OR mi.site IN (SELECT site_id FROM allowed_sites))
        AND (
          v_search = ''
          OR coalesce(mi.name, '') ILIKE '%' || v_search || '%'
          OR coalesce(mi.box, '') ILIKE '%' || v_search || '%'
        )
    ),
    movement_out AS (
      SELECT
        'move_out'::text AS movement_type,
        mo.id,
        mo.created_at,
        mo.site,
        mo.name,
        mo.box,
        mo.start_date,
        mo.taille,
        mo.size_code,
        mo.id_client,
        mo.is_empty,
        mo.is_clean,
        mo.comments,
        NULL::boolean AS poster_ok,
        mo.leave_date,
        NULL::boolean AS has_loxx_on_door,
        mo.has_loxx,
        jsonb_build_object('id', a.id, 'firstname', a.firstname, 'lastname', a.lastname) AS created_by,
        jsonb_build_object('id', s.id, 'name', s.name, 'site_code', s.site_code) AS site_info
      FROM move_out mo
      LEFT JOIN agent a ON a.id = mo.created_by
      LEFT JOIN site s ON s.id = mo.site
      WHERE (v_type IN ('all', 'move_out'))
        AND (site_id_param IS NULL OR mo.site = site_id_param)
        AND (allowed_site_ids_param IS NULL OR mo.site IN (SELECT site_id FROM allowed_sites))
        AND (
          v_search = ''
          OR coalesce(mo.name, '') ILIKE '%' || v_search || '%'
          OR coalesce(mo.box, '') ILIKE '%' || v_search || '%'
        )
    ),
    unified AS (
      SELECT * FROM movement_in
      UNION ALL
      SELECT * FROM movement_out
    ),
    counted AS (
      SELECT count(*)::integer AS total_count
      FROM unified
    ),
    page_plus_one AS (
      SELECT *
      FROM unified
      ORDER BY created_at DESC NULLS LAST, id DESC
      OFFSET v_offset
      LIMIT v_size + 1
    ),
    page_rows AS (
      SELECT * FROM page_plus_one LIMIT v_size
    ),
    has_next AS (
      SELECT (count(*) > v_size) AS has_next_page
      FROM page_plus_one
    )
    SELECT jsonb_build_object(
      'page', v_page,
      'page_size', v_size,
      'total_count', (SELECT total_count FROM counted),
      'has_next_page', (SELECT has_next_page FROM has_next),
      'items', coalesce(
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'movement_type', p.movement_type,
              'id', p.id,
              'created_at', p.created_at,
              'site', p.site,
              'name', p.name,
              'box', p.box,
              'start_date', p.start_date,
              'taille', p.taille,
              'size_code', p.size_code,
              'id_client', p.id_client,
              'is_empty', p.is_empty,
              'is_clean', p.is_clean,
              'comments', p.comments,
              'poster_ok', p.poster_ok,
              'leave_date', p.leave_date,
              'has_loxx_on_door', p.has_loxx_on_door,
              'has_loxx', p.has_loxx,
              'created_by', p.created_by,
              'site_info', p.site_info
            )
          )
          FROM page_rows p
        ),
        '[]'::jsonb
      )
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_movements_paginated(bigint, bigint[], text, text, integer, integer)
TO authenticated;
```

## Exemple d'appel

```sql
SELECT public.get_movements_paginated(
  site_id_param := NULL,
  allowed_site_ids_param := ARRAY[1,2],
  movement_type_param := 'all',
  search_param := 'A123',
  page_param := 0,
  page_size_param := 25
);
```
