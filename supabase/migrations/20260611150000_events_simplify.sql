-- Slim events table: id, name, description, url_image, url_video + person FK.

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

-- Upgrade path when the verbose v85 events table already exists.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'title'
  ) THEN
    ALTER TABLE public.events RENAME COLUMN title TO name;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'url_image'
  ) THEN
    ALTER TABLE public.events ADD COLUMN url_image text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'url_video'
  ) THEN
    ALTER TABLE public.events ADD COLUMN url_video text;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'events' AND column_name = 'remote_path'
  ) THEN
    UPDATE public.events
    SET url_image = remote_path
    WHERE url_image IS NULL AND remote_path IS NOT NULL;
  END IF;
END $$;

ALTER TABLE public.events DROP COLUMN IF EXISTS event_id;
ALTER TABLE public.events DROP COLUMN IF EXISTS domain;
ALTER TABLE public.events DROP COLUMN IF EXISTS meaning_score;
ALTER TABLE public.events DROP COLUMN IF EXISTS impact_score;
ALTER TABLE public.events DROP COLUMN IF EXISTS mood_pre;
ALTER TABLE public.events DROP COLUMN IF EXISTS mood_post;
ALTER TABLE public.events DROP COLUMN IF EXISTS impact_desc_who;
ALTER TABLE public.events DROP COLUMN IF EXISTS impact_desc_how;
ALTER TABLE public.events DROP COLUMN IF EXISTS local_path;
ALTER TABLE public.events DROP COLUMN IF EXISTS remote_path;
ALTER TABLE public.events DROP COLUMN IF EXISTS device;
ALTER TABLE public.events DROP COLUMN IF EXISTS source;

DROP INDEX IF EXISTS events_person_domain_idx;

CREATE INDEX IF NOT EXISTS events_person_occurred_idx
  ON public.events (person_id, occurred_at DESC);

COMMENT ON TABLE public.events IS
  'Person-owned event: name, description, optional url_image / url_video (S3 or CDN URL).';
COMMENT ON COLUMN public.events.url_image IS 'Public or presigned URL / S3 key for cover image.';
COMMENT ON COLUMN public.events.url_video IS 'Public or presigned URL / S3 key for video.';
