-- Fix OVL v2: Gérer les cas où box.floor_id peut être NULL
--
-- Si box.floor_id est NULL, on ne peut pas joindre floor. Les OVL de ces boxes
-- disparaissent. Cette version tente aussi de récupérer le site via floor.site
-- quand floor existe. Pour les boxes sans floor_id, l'OVL ne sera pas affichée
-- (il faudrait potentiellement ajouter un site_id sur ovl ou box).
--
-- Alternative testée: utiliser une sous-requête EXISTS pour éviter les doublons
-- si une OVL verrouille plusieurs boxes.

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
    -- OVL: filtre par site via box->floor->site
    -- Utilisation de EXISTS pour éviter doublons si une OVL verrouille plusieurs boxes
    'ovls', (
      SELECT COALESCE(json_agg(ovl_data), json_build_array())
      FROM (
        SELECT json_build_object(
          'id', o.id, 'number', o.number, 'code', o.code, 'date_time', o.date_time,
          'customer_id', o.customer_id,
          'operator', json_build_object('id', a.id, 'firstname', a.firstname, 'lastname', a.lastname)
        ) AS ovl_data
        FROM ovl o
        LEFT JOIN agent a ON o.operator = a.id
        WHERE o.date_time::date = report_date
          AND (
            -- Chemin standard: OVL -> box(locked) -> floor -> site
            EXISTS (
              SELECT 1 FROM box b
              INNER JOIN floor f ON b.floor_id = f.id
              WHERE b.locked = o.id AND f.site = site_id_val
            )
          )
      ) sub
    )
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
