-- Person-owned events + many-to-many skill impact (EventSkill junction).
-- Media lives on S3; store canonical key in events.remote_path.

-- Align skills with Drift v83+ (point-based XP).
ALTER TABLE public.skills
  ADD COLUMN IF NOT EXISTS point integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS achieved_points integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS event_id uuid;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'skills'
      AND column_name = 'years_of_experience'
  ) THEN
    UPDATE public.skills
    SET point = years_of_experience
    WHERE point = 0 AND years_of_experience > 0;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES public.organizations (id) ON DELETE SET NULL,
  person_id uuid NOT NULL REFERENCES public.persons (id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  url_image text,
  url_video text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS events_person_occurred_idx
  ON public.events (person_id, occurred_at DESC);

COMMENT ON TABLE public.events IS
  'Person-owned event: name, description, optional url_image / url_video.';
COMMENT ON COLUMN public.events.url_image IS
  'Image URL or S3 object key — fetch via presigned URL / backend.';
COMMENT ON COLUMN public.events.url_video IS
  'Video URL or S3 object key.';

CREATE TABLE IF NOT EXISTS public.event_skills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES public.organizations (id) ON DELETE SET NULL,
  person_id uuid NOT NULL REFERENCES public.persons (id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public.events (id) ON DELETE CASCADE,
  skill_id uuid NOT NULL REFERENCES public.skills (id) ON DELETE CASCADE,
  earning_point integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT event_skills_unique_pair UNIQUE (event_id, skill_id),
  CONSTRAINT event_skills_earning_nonneg CHECK (earning_point >= 0)
);

CREATE INDEX IF NOT EXISTS event_skills_person_idx
  ON public.event_skills (person_id);

CREATE INDEX IF NOT EXISTS event_skills_skill_idx
  ON public.event_skills (skill_id);

COMMENT ON TABLE public.event_skills IS
  'Junction: which events affected which skills, with optional earning_point.';

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_skills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own events" ON public.events;
CREATE POLICY "Users manage own events"
ON public.events
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);

DROP POLICY IF EXISTS "Users manage own event_skills" ON public.event_skills;
CREATE POLICY "Users manage own event_skills"
ON public.event_skills
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);

-- PowerSync publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'powersync'
  ) THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'powersync' AND schemaname = 'public' AND tablename = 'events'
  ) THEN
    ALTER PUBLICATION powersync ADD TABLE public.events;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'powersync' AND schemaname = 'public' AND tablename = 'event_skills'
  ) THEN
    ALTER PUBLICATION powersync ADD TABLE public.event_skills;
  END IF;
END $$;
