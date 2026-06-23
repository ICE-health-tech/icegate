-- Query indexes for goals (SDLC board, project tasks, sync filters).
CREATE INDEX IF NOT EXISTS goals_person_id_idx ON public.goals (person_id);
CREATE INDEX IF NOT EXISTS goals_project_id_idx ON public.goals (project_id);
CREATE INDEX IF NOT EXISTS goals_project_category_idx
  ON public.goals (project_id, category);
