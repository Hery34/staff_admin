-- Fix OVL: Filtrer par ovl.site + comparaison de date robuste (timezone)
--
-- La table ovl a une colonne site (FK vers site(id)).
-- Problème possible: to_do_list.date_time est "sans timezone" (stocké en heure locale),
-- ovl.date_time est "avec timezone" (UTC). La comparaison ::date peut diverger selon
-- le fuseau du serveur. On utilise Europe/Paris pour cohérence.
--
-- À exécuter dans Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_daily_activities_for_report(report_id_param bigint)
RETURNS json AS $$
DECLARE
  site_id_val bigint;
  report_date date;
  result json;
BEGIN
  SELECT tdl.site_id, tdl.date_time::date
  INTO site_id_val, report_date
  FROM report r
  JOIN to_do_list tdl ON r.to_do_list = tdl.id
  WHERE r.id = report_id_param;
  
  IF site_id_val IS NULL THEN
    RETURN json_build_object(
      'move_ins', json_build_array(),
      'move_outs', json_build_array(),
      'ovls', json_build_array()
    );
  END IF;
  
  SELECT json_build_object(
    'move_ins', (
      SELECT json_agg(
        json_build_object(
          'id', mi.id, 'created_at', mi.created_at, 'name', mi.name, 'box', mi.box,
          'start_date', mi.start_date, 'taille', mi.taille, 'size_code', mi.size_code,
          'id_client', mi.id_client, 'is_empty', mi.is_empty, 'has_loxx_on_door', mi.has_loxx_on_door,
          'is_clean', mi.is_clean, 'comments', mi.comments, 'poster_ok', mi.poster_ok,
          'created_by', json_build_object('id', a.id, 'firstname', a.firstname, 'lastname', a.lastname)
        )
      )
      FROM move_in mi
      LEFT JOIN agent a ON mi.created_by = a.id
      WHERE mi.site = site_id_val AND mi.created_at::date = report_date
    ),
    'move_outs', (
      SELECT json_agg(
        json_build_object(
          'id', mo.id, 'created_at', mo.created_at, 'name', mo.name, 'box', mo.box,
          'start_date', mo.start_date, 'taille', mo.taille, 'size_code', mo.size_code,
          'id_client', mo.id_client, 'is_empty', mo.is_empty, 'has_loxx', mo.has_loxx,
          'is_clean', mo.is_clean, 'comments', mo.comments, 'leave_date', mo.leave_date,
          'created_by', json_build_object('id', a.id, 'firstname', a.firstname, 'lastname', a.lastname)
        )
      )
      FROM move_out mo
      LEFT JOIN agent a ON mo.created_by = a.id
      WHERE mo.site = site_id_val AND mo.created_at::date = report_date
    ),
    'ovls', COALESCE((
      SELECT json_agg(
        json_build_object(
          'id', o.id, 'number', o.number, 'code', o.code, 'date_time', o.date_time,
          'customer_id', o.customer_id,
          'operator', json_build_object('id', a.id, 'firstname', a.firstname, 'lastname', a.lastname)
        )
      )
      FROM ovl o
      LEFT JOIN agent a ON o.operator = a.id
      WHERE o.site = site_id_val
        AND (o.date_time AT TIME ZONE 'Europe/Paris')::date = report_date
        AND (o.ovl_removed IS NULL OR o.ovl_removed = false)
    ), json_build_array())
  ) INTO result;
  
  IF result IS NULL OR result->'move_ins' IS NULL THEN
    result := json_build_object(
      'move_ins', COALESCE(result->'move_ins', json_build_array()),
      'move_outs', COALESCE(result->'move_outs', json_build_array()),
      'ovls', COALESCE(result->'ovls', json_build_array())
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
