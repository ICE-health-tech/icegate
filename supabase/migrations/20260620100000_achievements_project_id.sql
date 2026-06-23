-- Link achievements / photo stories to a project for filtering and navigation.
ALTER TABLE public.achievements
  ADD COLUMN IF NOT EXISTS project_id TEXT;

CREATE INDEX IF NOT EXISTS achievements_person_project_idx
  ON public.achievements (person_id, project_id);
