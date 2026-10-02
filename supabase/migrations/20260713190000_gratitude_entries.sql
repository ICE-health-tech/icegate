-- Gratitude entries (Biết ơn tab) — sync with Drift v100.

CREATE TABLE IF NOT EXISTS public.gratitude_entries (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  name text NOT NULL,
  kind text NOT NULL DEFAULT 'person',
  note text,
  facebook_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gratitude_entries_person
  ON public.gratitude_entries(person_id);

ALTER TABLE public.gratitude_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own gratitude_entries"
  ON public.gratitude_entries FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);
