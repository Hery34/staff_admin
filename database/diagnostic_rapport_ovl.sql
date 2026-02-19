-- Diagnostic: vérifier pourquoi l'OVL 61 n'apparaît pas dans le rapport
--
-- 1. Trouver le rapport Pierre Bénite (site 9) pour le 18/02/2026
SELECT r.id AS report_id, tdl.id AS todo_id, tdl.site_id, tdl.date_time,
       tdl.date_time::date AS report_date,
       s.name AS site_name
FROM report r
JOIN to_do_list tdl ON r.to_do_list = tdl.id
LEFT JOIN site s ON tdl.site_id = s.id
WHERE tdl.site_id = 9
  AND tdl.date_time::date = '2026-02-18'
ORDER BY r.id DESC;

-- 2. Avec l'id du rapport ci-dessus, simuler ce que la fonction récupère
-- (remplacer 123 par le report_id réel)
/*
DO $$
DECLARE
  site_id_val bigint;
  report_date date;
  ovl_count int;
BEGIN
  SELECT tdl.site_id, tdl.date_time::date
  INTO site_id_val, report_date
  FROM report r JOIN to_do_list tdl ON r.to_do_list = tdl.id
  WHERE r.id = 123;
  
  RAISE NOTICE 'site_id_val=%, report_date=%', site_id_val, report_date;
  
  SELECT count(*) INTO ovl_count
  FROM ovl o
  WHERE o.site = site_id_val
    AND o.date_time::date = report_date
    AND (o.ovl_removed IS NULL OR o.ovl_removed = false);
  
  RAISE NOTICE 'OVL count (avec ::date)=%', ovl_count;
  
  -- Test avec timezone Paris
  SELECT count(*) INTO ovl_count
  FROM ovl o
  WHERE o.site = site_id_val
    AND (o.date_time AT TIME ZONE 'Europe/Paris')::date = report_date
    AND (o.ovl_removed IS NULL OR o.ovl_removed = false);
  
  RAISE NOTICE 'OVL count (avec Paris TZ)=%', ovl_count;
END $$;
*/

-- 3. Vérifier l'OVL 61 et les dates
SELECT id, number, code, date_time,
       date_time::date AS date_utc,
       (date_time AT TIME ZONE 'Europe/Paris')::date AS date_paris,
       site, ovl_removed
FROM ovl WHERE id = 61;
