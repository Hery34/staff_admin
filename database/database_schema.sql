-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.agent (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  firstname text NOT NULL,
  lastname text NOT NULL,
  email text NOT NULL UNIQUE,
  pin_code smallint NOT NULL,
  role USER-DEFINED NOT NULL,
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
  CONSTRAINT ovl_pkey PRIMARY KEY (id),
  CONSTRAINT ovl_operator_fkey FOREIGN KEY (operator) REFERENCES public.agent(id)
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