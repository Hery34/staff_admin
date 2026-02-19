-- Récupère un rapport par ID (SECURITY DEFINER pour contourner RLS)
-- Utilisé quand on arrive depuis "Activités du jour par site" où les rapports
-- sont retournés par get_activities_by_site_and_date (qui bypass RLS)
--
-- À exécuter dans Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_report_by_id(report_id_param bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'id', r.id,
    'date_time', r.date_time,
    'to_do_list', json_build_object(
      'date_time', tdl.date_time,
      'site_id', tdl.site_id,
      'site', json_build_object(
        'name', s.name,
        'site_code', s.site_code
      )
    ),
    'responsable', json_build_object(
      'firstname', a.firstname,
      'lastname', a.lastname
    )
  )
  INTO result
  FROM report r
  JOIN to_do_list tdl ON r.to_do_list = tdl.id
  LEFT JOIN site s ON tdl.site_id = s.id
  LEFT JOIN agent a ON r.responsable = a.id
  WHERE r.id = report_id_param;

  RETURN result;
END;
$$;
