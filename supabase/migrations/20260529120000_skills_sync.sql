-- Skills table for person library + project-linked practice XP (PowerSync / Supabase sync).
-- Matches Drift [SkillsTable] and [PowersyncSchema] `skills`.

CREATE TABLE IF NOT EXISTS public.skills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES public.organizations (id) ON DELETE SET NULL,
  skill_id text,
  person_id uuid REFERENCES public.persons (id) ON DELETE CASCADE,
  skill_name text NOT NULL,
  skill_category text,
  proficiency_level text NOT NULL DEFAULT 'beginner',
  years_of_experience integer NOT NULL DEFAULT 0,
  description text,
  is_featured boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS skills_person_id_idx ON public.skills (person_id);
CREATE INDEX IF NOT EXISTS skills_person_category_idx ON public.skills (person_id, skill_category);

ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own skills" ON public.skills;
CREATE POLICY "Users manage own skills"
ON public.skills
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);

-- PowerSync publication (safe if already added).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'powersync' AND schemaname = 'public' AND tablename = 'skills'
  ) THEN
    NULL;
  ELSIF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'powersync') THEN
    ALTER PUBLICATION powersync ADD TABLE public.skills;
  END IF;
END $$;

COMMENT ON TABLE public.skills IS 'Per-person skill library (person:library) and project skills (project:<id>). years_of_experience stores practice XP.';
COMMENT ON COLUMN public.skills.skill_category IS 'person:library | mind:boost | project:<project_uuid>';
COMMENT ON COLUMN public.skills.years_of_experience IS 'Practice XP total (not calendar years).';
