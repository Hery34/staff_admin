-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.agent (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  firstname text NOT NULL,
  lastname text NOT NULL,
  email text NOT NULL UNIQUE,
  pin_code smallint,
  role USER-DEFINED NOT NULL,
  statut_compte USER-DEFINED DEFAULT 'en_attente_confirmation'::statut_agent,
  CONSTRAINT agent_pkey PRIMARY KEY (id)
);
CREATE TABLE public.alerte_incendie_tasks (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name character varying,
  description text,
  type USER-DEFINED NOT NULL DEFAULT 'alerte'::type_alerte,
  CONSTRAINT alerte_incendie_tasks_pkey PRIMARY KEY (id)
);
CREATE TABLE public.box (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL UNIQUE,
  number smallint NOT NULL,
  is_available boolean NOT NULL DEFAULT true,
  sized_box real NOT NULL,
  locked bigint,
  floor_id bigint,
  size_code text NOT NULL,
  CONSTRAINT box_pkey PRIMARY KEY (id),
  CONSTRAINT box_floor_id_fkey FOREIGN KEY (floor_id) REFERENCES public.floor(id),
  CONSTRAINT box_locked_fkey FOREIGN KEY (locked) REFERENCES public.ovl(id)
);
CREATE TABLE public.clients_pro (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  Fullname text,
  sitecode text,
  MainTown text,
  MainCountry text,
  Email text,
  EstEmailPrincipal text,
  RCS text,
  siren text,
  effectif text,
  ca text,
  capital text,
  CONSTRAINT clients_pro_pkey PRIMARY KEY (id)
);
CREATE TABLE public.fire_alert_report (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  date timestamp with time zone NOT NULL DEFAULT now(),
  floor bigint,
  alert_type USER-DEFINED DEFAULT 'fausse alerte'::type_alerte,
  is_running boolean DEFAULT false,
  created_by bigint NOT NULL,
  closed_at timestamp with time zone,
  closed_by bigint,
  site bigint,
  declencheur USER-DEFINED,
  is_complete boolean DEFAULT false,
  CONSTRAINT fire_alert_report_pkey PRIMARY KEY (id),
  CONSTRAINT fire_alert_report_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES public.agent(id),
  CONSTRAINT fire_alert_report_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.agent(id),
  CONSTRAINT fire_alert_report_floor_fkey FOREIGN KEY (floor) REFERENCES public.floor(id),
  CONSTRAINT fire_alert_report_site_fkey FOREIGN KEY (site) REFERENCES public.site(id)
);
CREATE TABLE public.fire_alert_tasks (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  fire_alert_report_id bigint NOT NULL,
  task_id bigint NOT NULL,
  is_done boolean DEFAULT false,
  is_modified boolean DEFAULT false,
  completed_at timestamp with time zone,
  completed_by bigint,
  notes text,
  CONSTRAINT fire_alert_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT fire_alert_tasks_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES public.agent(id),
  CONSTRAINT fire_alert_tasks_fire_alert_report_id_fkey FOREIGN KEY (fire_alert_report_id) REFERENCES public.fire_alert_report(id),
  CONSTRAINT fire_alert_tasks_task_id_fkey1 FOREIGN KEY (task_id) REFERENCES public.alerte_incendie_tasks(id)
);
CREATE TABLE public.floor (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  level USER-DEFINED NOT NULL,
  site bigint,
  CONSTRAINT floor_pkey PRIMARY KEY (id),
  CONSTRAINT floor_site_fkey FOREIGN KEY (site) REFERENCES public.site(id)
);
CREATE TABLE public.move_in (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  site bigint NOT NULL,
  name text NOT NULL,
  box text NOT NULL,
  start_date text,
  taille text,
  size_code text,
  id_client text,
  is_empty boolean NOT NULL DEFAULT false,
  has_loxx_on_door boolean NOT NULL DEFAULT false,
  is_clean boolean NOT NULL DEFAULT false,
  created_by bigint,
  comments text,
  poster_ok boolean DEFAULT true,
  CONSTRAINT move_in_pkey PRIMARY KEY (id),
  CONSTRAINT move_in_site_fkey FOREIGN KEY (site) REFERENCES public.site(id),
  CONSTRAINT move_in_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.agent(id)
);
CREATE TABLE public.move_out (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  site bigint NOT NULL,
  name text NOT NULL,
  box text NOT NULL,
  start_date text,
  taille text,
  size_code text,
  id_client text,
  is_empty boolean NOT NULL DEFAULT false,
  has_loxx boolean NOT NULL DEFAULT false,
  is_clean boolean NOT NULL DEFAULT false,
  created_by bigint,
  comments text,
  leave_date text,
  CONSTRAINT move_out_pkey PRIMARY KEY (id),
  CONSTRAINT move_out_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.agent(id),
  CONSTRAINT move_out_site_fkey FOREIGN KEY (site) REFERENCES public.site(id)
);
CREATE TABLE public.ovl (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  number text,
  code smallint,
  date_time timestamp with time zone,
  customer_id text,
  operator bigint,
  ovl_removed boolean DEFAULT false,
  removed_date timestamp with time zone,
  removing_operator bigint,
  site bigint,
  CONSTRAINT ovl_pkey PRIMARY KEY (id),
  CONSTRAINT ovl_operator_fkey FOREIGN KEY (operator) REFERENCES public.agent(id),
  CONSTRAINT ovl_removing_operator_fkey FOREIGN KEY (removing_operator) REFERENCES public.agent(id),
  CONSTRAINT ovl_site_fkey FOREIGN KEY (site) REFERENCES public.site(id)
);
CREATE TABLE public.report (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL UNIQUE,
  date_time timestamp without time zone NOT NULL,
  to_do_list bigint NOT NULL,
  responsable bigint NOT NULL,
  CONSTRAINT report_pkey PRIMARY KEY (id),
  CONSTRAINT report_responsable_fkey FOREIGN KEY (responsable) REFERENCES public.agent(id),
  CONSTRAINT report_to_do_list_fkey FOREIGN KEY (to_do_list) REFERENCES public.to_do_list(id)
);
CREATE TABLE public.report_detail (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  report bigint NOT NULL,
  task bigint,
  comment text,
  photo_url text,
  CONSTRAINT report_detail_pkey PRIMARY KEY (id),
  CONSTRAINT report_detail_report_fkey FOREIGN KEY (report) REFERENCES public.report(id),
  CONSTRAINT report_detail_task_fkey FOREIGN KEY (task) REFERENCES public.task_of_day(id)
);
CREATE TABLE public.site (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL UNIQUE,
  site_code text NOT NULL UNIQUE,
  latitude real NOT NULL,
  longitude real NOT NULL,
  email text,
  CONSTRAINT site_pkey PRIMARY KEY (id)
);
CREATE TABLE public.task (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL,
  description text,
  category USER-DEFINED NOT NULL,
  chronology USER-DEFINED NOT NULL,
  photo_url text,
  importance USER-DEFINED NOT NULL DEFAULT 'bloquant'::importance,
  is_daily boolean NOT NULL DEFAULT true,
  CONSTRAINT task_pkey PRIMARY KEY (id)
);
CREATE TABLE public.task_of_day (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  to_do_list bigint,
  task_site bigint,
  is_done boolean NOT NULL DEFAULT false,
  comment text,
  photo text,
  CONSTRAINT task_of_day_pkey PRIMARY KEY (id),
  CONSTRAINT task_of_day_task_site_fkey FOREIGN KEY (task_site) REFERENCES public.task_site(id),
  CONSTRAINT task_of_day_to_do_list_fkey FOREIGN KEY (to_do_list) REFERENCES public.to_do_list(id)
);
CREATE TABLE public.task_site (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  site bigint,
  task bigint,
  recurrence USER-DEFINED NOT NULL DEFAULT 'daily'::recurrence,
  CONSTRAINT task_site_pkey PRIMARY KEY (id),
  CONSTRAINT task_site_site_fkey FOREIGN KEY (site) REFERENCES public.site(id),
  CONSTRAINT task_site_task_fkey FOREIGN KEY (task) REFERENCES public.task(id)
);
CREATE TABLE public.to_do_list (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  date_time timestamp without time zone NOT NULL,
  site_id bigint,
  CONSTRAINT to_do_list_pkey PRIMARY KEY (id),
  CONSTRAINT to_do_list_site_id_param_fkey FOREIGN KEY (site_id) REFERENCES public.site(id)
);

-- Function RPC to get daily activities (move-in, move-out, OVL) for a report
CREATE OR REPLACE FUNCTION get_daily_activities_for_report(report_id_param bigint)
RETURNS json AS $$
DECLARE
  todo_list_record RECORD;
  site_id_val bigint;
  report_date date;
  result json;
BEGIN
  -- Get the to_do_list information for the report
  SELECT tdl.site_id, tdl.date_time::date
  INTO site_id_val, report_date
  FROM report r
  JOIN to_do_list tdl ON r.to_do_list = tdl.id
  WHERE r.id = report_id_param;
  
  -- If no report found, return empty result
  IF site_id_val IS NULL THEN
    RETURN json_build_object(
      'move_ins', json_build_array(),
      'move_outs', json_build_array(),
      'ovls', json_build_array()
    );
  END IF;
  
  -- Build the result with move-ins, move-outs, and OVLs for the day
  SELECT json_build_object(
    'move_ins', (
      SELECT json_agg(
        json_build_object(
          'id', mi.id,
          'created_at', mi.created_at,
          'name', mi.name,
          'box', mi.box,
          'start_date', mi.start_date,
          'taille', mi.taille,
          'size_code', mi.size_code,
          'id_client', mi.id_client,
          'is_empty', mi.is_empty,
          'has_loxx_on_door', mi.has_loxx_on_door,
          'is_clean', mi.is_clean,
          'comments', mi.comments,
          'poster_ok', mi.poster_ok,
          'created_by', json_build_object(
            'id', a.id,
            'firstname', a.firstname,
            'lastname', a.lastname
          )
        )
      )
      FROM move_in mi
      LEFT JOIN agent a ON mi.created_by = a.id
      WHERE mi.site = site_id_val
        AND mi.created_at::date = report_date
    ),
    'move_outs', (
      SELECT json_agg(
        json_build_object(
          'id', mo.id,
          'created_at', mo.created_at,
          'name', mo.name,
          'box', mo.box,
          'start_date', mo.start_date,
          'taille', mo.taille,
          'size_code', mo.size_code,
          'id_client', mo.id_client,
          'is_empty', mo.is_empty,
          'has_loxx', mo.has_loxx,
          'is_clean', mo.is_clean,
          'comments', mo.comments,
          'leave_date', mo.leave_date,
          'created_by', json_build_object(
            'id', a.id,
            'firstname', a.firstname,
            'lastname', a.lastname
          )
        )
      )
      FROM move_out mo
      LEFT JOIN agent a ON mo.created_by = a.id
      WHERE mo.site = site_id_val
        AND mo.created_at::date = report_date
    ),
    'ovls', (
      SELECT json_agg(
        json_build_object(
          'id', o.id,
          'number', o.number,
          'code', o.code,
          'date_time', o.date_time,
          'customer_id', o.customer_id,
          'operator', json_build_object(
            'id', a.id,
            'firstname', a.firstname,
            'lastname', a.lastname
          )
        )
      )
      FROM ovl o
      LEFT JOIN agent a ON o.operator = a.id
      WHERE o.site = site_id_val
        AND o.date_time::date = report_date
        AND (o.ovl_removed IS NULL OR o.ovl_removed = false)
    )
  ) INTO result;
  
  -- Return empty arrays if null
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