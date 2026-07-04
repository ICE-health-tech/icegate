-- Bonuses: one-off bonus payments linked to a job position.
CREATE TABLE IF NOT EXISTS public.bonuses (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  job_position_id text REFERENCES public.job_positions(id) ON DELETE SET NULL,
  amount double precision NOT NULL,
  description text NOT NULL DEFAULT '',
  bonus_date timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bonuses_person ON public.bonuses(person_id);
CREATE INDEX IF NOT EXISTS idx_bonuses_job ON public.bonuses(job_position_id);

ALTER TABLE public.bonuses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own bonuses"
  ON public.bonuses FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);

COMMENT ON TABLE public.bonuses IS 'One-off bonus payments linked to job positions';
COMMENT ON COLUMN public.bonuses.job_position_id IS 'FK to job_positions — which job this bonus came from';
