-- Sub-projects: link child rows to parent project (matches Drift v79 / ice_gate local schema).

ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS parent_project_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'projects_parent_project_id_fkey'
  ) THEN
    ALTER TABLE public.projects
      ADD CONSTRAINT projects_parent_project_id_fkey
      FOREIGN KEY (parent_project_id) REFERENCES public.projects (id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_projects_parent_project_id
  ON public.projects (parent_project_id)
  WHERE parent_project_id IS NOT NULL;

COMMENT ON COLUMN public.projects.parent_project_id IS
  'When set, this project is a child of the referenced projects.id row.';
