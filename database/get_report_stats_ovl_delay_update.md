# Mise à jour SQL: statistique délai moyen OVL (pose -> retrait) par site

Exécute ce script dans **Supabase SQL Editor**.

```sql
CREATE OR REPLACE FUNCTION get_report_stats(
  start_date_param date,
  end_date_param date
)
RETURNS json AS $$
DECLARE
  expected_days_val int;
  result json;
BEGIN
  -- Nombre de jours ouvrés (lun-ven) dans la période
  SELECT count(*)::int INTO expected_days_val
  FROM generate_series(start_date_param, end_date_param, '1 day'::interval) d
  WHERE extract(isodow FROM d) BETWEEN 1 AND 5;

  -- Si période vide ou invalide, expected = 1 pour éviter division par zéro
  IF expected_days_val IS NULL OR expected_days_val = 0 THEN
    expected_days_val := 1;
  END IF;

  SELECT json_build_object(
    'expected_working_days', expected_days_val,
    'start_date', start_date_param,
    'end_date', end_date_param,
    'closure_by_site', (
      SELECT COALESCE(json_agg(row_to_json(t)), json_build_array())
      FROM (
        SELECT
          s.id AS site_id,
          s.name AS site_name,
          s.site_code,
          COALESCE(rpt.cnt, 0)::int AS reports_count,
          expected_days_val AS expected_days,
          round((COALESCE(rpt.cnt, 0)::numeric / expected_days_val * 100), 1) AS rate_pct
        FROM site s
        LEFT JOIN (
          SELECT tdl.site_id, count(*) AS cnt
          FROM report r
          JOIN to_do_list tdl ON r.to_do_list = tdl.id
          WHERE tdl.date_time::date >= start_date_param
            AND tdl.date_time::date <= end_date_param
            AND extract(isodow FROM tdl.date_time::date) BETWEEN 1 AND 5
          GROUP BY tdl.site_id
        ) rpt ON s.id = rpt.site_id
        WHERE s.id IN (SELECT site_id FROM agent_sites)
        ORDER BY COALESCE(rpt.cnt, 0) ASC, s.name
      ) t
    ),
    'ovl_delay_by_site', (
      SELECT COALESCE(json_agg(row_to_json(t)), json_build_array())
      FROM (
        SELECT
          s.id AS site_id,
          s.name AS site_name,
          s.site_code,
          count(*)::int AS removed_count,
          round(avg(EXTRACT(EPOCH FROM (o.removed_date - o.date_time)) / 86400.0)::numeric, 2) AS avg_delay_days
        FROM ovl o
        JOIN site s ON s.id = o.site
        WHERE coalesce(o.ovl_removed, false) = true
          AND o.date_time IS NOT NULL
          AND o.removed_date IS NOT NULL
          AND o.removed_date >= start_date_param::timestamp
          AND o.removed_date < (end_date_param::timestamp + interval '1 day')
          AND s.id IN (SELECT site_id FROM agent_sites)
        GROUP BY s.id, s.name, s.site_code
        ORDER BY avg_delay_days DESC, s.name
      ) t
    ),
    'top_agents', (
      SELECT COALESCE(json_agg(row_to_json(t)), json_build_array())
      FROM (
        SELECT
          a.id AS agent_id,
          a.firstname,
          a.lastname,
          count(*)::int AS reports_count
        FROM report r
        JOIN to_do_list tdl ON r.to_do_list = tdl.id
        JOIN agent a ON r.responsable = a.id
        WHERE tdl.date_time::date >= start_date_param
          AND tdl.date_time::date <= end_date_param
        GROUP BY a.id, a.firstname, a.lastname
        ORDER BY count(*) DESC
        LIMIT 20
      ) t
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
