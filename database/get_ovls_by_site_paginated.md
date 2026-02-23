# RPC Supabase: OVL par site (pagination + statut + recherche + total)

Exécute ce script dans **Supabase SQL Editor**.

```sql
CREATE OR REPLACE FUNCTION public.get_ovls_by_site_paginated(
  site_id_param bigint,
  status_param text DEFAULT 'all',
  search_param text DEFAULT '',
  page_param integer DEFAULT 0,
  page_size_param integer DEFAULT 25
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status text := lower(coalesce(status_param, 'all'));
  v_search text := btrim(coalesce(search_param, ''));
  v_page integer := GREATEST(coalesce(page_param, 0), 0);
  v_size integer := GREATEST(coalesce(page_size_param, 25), 1);
  v_offset integer := GREATEST(coalesce(page_param, 0), 0) * GREATEST(coalesce(page_size_param, 25), 1);
BEGIN
  IF v_status NOT IN ('all', 'active', 'removed') THEN
    v_status := 'all';
  END IF;

  RETURN (
    WITH filtered AS (
      SELECT
        o.id,
        o.site,
        o.number,
        o.code,
        o.date_time,
        o.customer_id,
        coalesce(o.ovl_removed, false) AS ovl_removed,
        o.removed_date,
        op.id AS operator_id,
        op.firstname AS operator_firstname,
        op.lastname AS operator_lastname,
        rop.id AS removing_operator_id,
        rop.firstname AS removing_operator_firstname,
        rop.lastname AS removing_operator_lastname,
        s.id AS site_info_id,
        s.name AS site_info_name,
        s.site_code AS site_info_code
      FROM public.ovl o
      LEFT JOIN public.agent op ON op.id = o.operator
      LEFT JOIN public.agent rop ON rop.id = o.removing_operator
      LEFT JOIN public.site s ON s.id = o.site
      WHERE o.site = site_id_param
        AND (
          v_status = 'all'
          OR (v_status = 'active' AND coalesce(o.ovl_removed, false) = false)
          OR (v_status = 'removed' AND coalesce(o.ovl_removed, false) = true)
        )
        AND (
          v_search = ''
          OR coalesce(o.number, '') ILIKE '%' || v_search || '%'
          OR coalesce(o.customer_id, '') ILIKE '%' || v_search || '%'
          OR (v_search ~ '^[0-9]+$' AND o.code = v_search::integer)
        )
    ),
    counted AS (
      SELECT count(*)::integer AS total_count
      FROM filtered
    ),
    page_plus_one AS (
      SELECT *
      FROM filtered
      ORDER BY date_time DESC NULLS LAST, id DESC
      OFFSET v_offset
      LIMIT v_size + 1
    ),
    page_rows AS (
      SELECT *
      FROM page_plus_one
      LIMIT v_size
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
              'id', p.id,
              'site', p.site,
              'number', p.number,
              'code', p.code,
              'date_time', p.date_time,
              'customer_id', p.customer_id,
              'ovl_removed', p.ovl_removed,
              'removed_date', p.removed_date,
              'operator',
                CASE
                  WHEN p.operator_id IS NULL THEN NULL
                  ELSE jsonb_build_object(
                    'id', p.operator_id,
                    'firstname', p.operator_firstname,
                    'lastname', p.operator_lastname
                  )
                END,
              'removing_operator',
                CASE
                  WHEN p.removing_operator_id IS NULL THEN NULL
                  ELSE jsonb_build_object(
                    'id', p.removing_operator_id,
                    'firstname', p.removing_operator_firstname,
                    'lastname', p.removing_operator_lastname
                  )
                END,
              'site_info',
                CASE
                  WHEN p.site_info_id IS NULL THEN NULL
                  ELSE jsonb_build_object(
                    'id', p.site_info_id,
                    'name', p.site_info_name,
                    'site_code', p.site_info_code
                  )
                END
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

GRANT EXECUTE ON FUNCTION public.get_ovls_by_site_paginated(bigint, text, text, integer, integer)
TO authenticated;
```

## Exemple d'appel

```sql
SELECT public.get_ovls_by_site_paginated(
  site_id_param := 1,
  status_param := 'active',
  search_param := '',
  page_param := 0,
  page_size_param := 25
);
```

## Valeurs possibles pour `status_param`

- `all`
- `active`
- `removed`
