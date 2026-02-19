-- Requêtes de diagnostic pour comprendre pourquoi une OVL n'apparaît pas
--
-- 1. Lister les OVL récentes avec leur lien box/floor/site (s'il existe)
SELECT 
  o.id AS ovl_id,
  o.number,
  o.date_time,
  b.id AS box_id,
  b.floor_id,
  f.id AS floor_id_check,
  f.site AS site_id,
  s.name AS site_name
FROM ovl o
LEFT JOIN box b ON b.locked = o.id
LEFT JOIN floor f ON b.floor_id = f.id
LEFT JOIN site s ON f.site = s.id
WHERE o.date_time >= current_date - interval '7 days'
ORDER BY o.date_time DESC;

-- 2. Vérifier le site du rapport Pierre Bénite
SELECT r.id AS report_id, tdl.site_id, s.name AS site_name, tdl.date_time::date
FROM report r
JOIN to_do_list tdl ON r.to_do_list = tdl.id
LEFT JOIN site s ON tdl.site_id = s.id
WHERE s.name ILIKE '%pierre%' OR s.name ILIKE '%bénite%' OR s.name ILIKE '%benite%';
