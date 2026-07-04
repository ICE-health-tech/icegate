-- Dev Tools quick-access browser tabs (per person, synced from ice_gate app).
CREATE TABLE IF NOT EXISTS public.dev_quick_tabs (
  id uuid PRIMARY KEY,
  person_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  title text NOT NULL DEFAULT '',
  full_url text NOT NULL DEFAULT '',
  sort_order integer NOT NULL DEFAULT 0,
  is_pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.dev_quick_tabs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS dev_quick_tabs_select_own ON public.dev_quick_tabs;
CREATE POLICY dev_quick_tabs_select_own
  ON public.dev_quick_tabs FOR SELECT
  USING (auth.uid() = person_id);

DROP POLICY IF EXISTS dev_quick_tabs_insert_own ON public.dev_quick_tabs;
CREATE POLICY dev_quick_tabs_insert_own
  ON public.dev_quick_tabs FOR INSERT
  WITH CHECK (auth.uid() = person_id);

DROP POLICY IF EXISTS dev_quick_tabs_update_own ON public.dev_quick_tabs;
CREATE POLICY dev_quick_tabs_update_own
  ON public.dev_quick_tabs FOR UPDATE
  USING (auth.uid() = person_id);

DROP POLICY IF EXISTS dev_quick_tabs_delete_own ON public.dev_quick_tabs;
CREATE POLICY dev_quick_tabs_delete_own
  ON public.dev_quick_tabs FOR DELETE
  USING (auth.uid() = person_id);

CREATE INDEX IF NOT EXISTS dev_quick_tabs_person_id_idx
  ON public.dev_quick_tabs (person_id);

COMMENT ON TABLE public.dev_quick_tabs IS
  'Dev Tools saved browser tabs — title + URL per person (credentials stay on device).';
