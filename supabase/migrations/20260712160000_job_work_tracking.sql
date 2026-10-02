-- Job work tracking: days, plans, time logs, custom sub-tasks (sync with Drift v98).

CREATE TABLE IF NOT EXISTS public.job_work_days (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  job_position_id text NOT NULL REFERENCES public.job_positions(id) ON DELETE CASCADE,
  work_date timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (person_id, job_position_id, work_date)
);

CREATE TABLE IF NOT EXISTS public.job_work_day_plans (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  job_position_id text NOT NULL REFERENCES public.job_positions(id) ON DELETE CASCADE,
  work_date timestamptz NOT NULL,
  planned_minutes integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (person_id, job_position_id, work_date)
);

CREATE TABLE IF NOT EXISTS public.job_time_logs (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  job_position_id text NOT NULL REFERENCES public.job_positions(id) ON DELETE CASCADE,
  work_date timestamptz NOT NULL,
  task_category text NOT NULL,
  minutes integer NOT NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.job_sub_tasks (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  job_position_id text NOT NULL REFERENCES public.job_positions(id) ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_job_work_days_person ON public.job_work_days(person_id);
CREATE INDEX IF NOT EXISTS idx_job_work_day_plans_person ON public.job_work_day_plans(person_id);
CREATE INDEX IF NOT EXISTS idx_job_time_logs_person ON public.job_time_logs(person_id);
CREATE INDEX IF NOT EXISTS idx_job_sub_tasks_person ON public.job_sub_tasks(person_id);

ALTER TABLE public.job_work_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_work_day_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_time_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_sub_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own job_work_days"
  ON public.job_work_days FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);

CREATE POLICY "Users manage own job_work_day_plans"
  ON public.job_work_day_plans FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);

CREATE POLICY "Users manage own job_time_logs"
  ON public.job_time_logs FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);

CREATE POLICY "Users manage own job_sub_tasks"
  ON public.job_sub_tasks FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);
