-- Activités du jour par site et date (avec ou sans rapport clôturé)
--
-- Permet d'afficher tout ce qui a été fait sur un site un jour donné, même si
-- la journée n'a pas été clôturée par signature PIN.
-- Les tâches non validées sont clairement identifiées (is_validated = false).
--
-- À exécuter dans Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_activities_by_site_and_date(
  site_id_param bigint,
  date_param date
)
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'move_ins', COALESCE((
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
      WHERE mi.site = site_id_param
        AND (mi.created_at AT TIME ZONE 'Europe/Paris')::date = date_param
    ), json_build_array()),
    'move_outs', COALESCE((
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
      WHERE mo.site = site_id_param
        AND (mo.created_at AT TIME ZONE 'Europe/Paris')::date = date_param
    ), json_build_array()),
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
      WHERE o.site = site_id_param
        AND (o.date_time AT TIME ZONE 'Europe/Paris')::date = date_param
        AND (o.ovl_removed IS NULL OR o.ovl_removed = false)
    ), json_build_array()),
    'tasks', COALESCE((
      SELECT json_agg(
        json_build_object(
          'id', tod.id,
          'task_name', t.name,
          'comment', tod.comment,
          'photo', tod.photo,
          'is_validated', EXISTS (
            SELECT 1 FROM report_detail rd
            JOIN report r ON rd.report = r.id
            JOIN to_do_list tdl2 ON r.to_do_list = tdl2.id
            WHERE rd.task = tod.id
              AND tdl2.site_id = site_id_param
              AND tdl2.date_time::date = date_param
          )
        )
      )
      FROM task_of_day tod
      JOIN to_do_list tdl ON tod.to_do_list = tdl.id
      JOIN task_site ts ON tod.task_site = ts.id
      JOIN task t ON ts.task = t.id
      WHERE tdl.site_id = site_id_param
        AND tdl.date_time::date = date_param
        AND tod.is_done = true
    ), json_build_array()),
    'reports', COALESCE((
      SELECT json_agg(
        json_build_object(
          'id', r.id,
          'date_time', r.date_time,
          'responsable', json_build_object(
            'firstname', a.firstname,
            'lastname', a.lastname
          )
        )
      )
      FROM report r
      JOIN to_do_list tdl ON r.to_do_list = tdl.id
      LEFT JOIN agent a ON r.responsable = a.id
      WHERE tdl.site_id = site_id_param
        AND tdl.date_time::date = date_param
    ), json_build_array())
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
