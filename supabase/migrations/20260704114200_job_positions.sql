-- Job positions: tracks employment / contract history per person.
-- end_date NULL means the position is current.
CREATE TABLE IF NOT EXISTS public.job_positions (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  employer text NOT NULL DEFAULT '',
  job_title text NOT NULL DEFAULT '',
  contract_type text NOT NULL DEFAULT 'full_time',
  start_date timestamptz NOT NULL DEFAULT now(),
  end_date timestamptz,
  linked_income_id text REFERENCES public.recurring_incomes(id) ON DELETE SET NULL,
  linked_project_id text,
  notes text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_job_positions_person ON public.job_positions(person_id);
CREATE INDEX IF NOT EXISTS idx_job_positions_current ON public.job_positions(person_id) WHERE end_date IS NULL;

ALTER TABLE public.job_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own job_positions"
  ON public.job_positions FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);

COMMENT ON TABLE public.job_positions IS 'Employment / contract positions linked to income streams and projects';
COMMENT ON COLUMN public.job_positions.contract_type IS 'full_time, part_time, freelance, internship, contract';
COMMENT ON COLUMN public.job_positions.linked_income_id IS 'FK to recurring_incomes — the salary/income stream for this job';
COMMENT ON COLUMN public.job_positions.linked_project_id IS 'Soft FK to projects (uuid stored as text) — the project this job contributes to';
