-- Extracted AI memory from captured screens (local app syncs via Drift + Supabase)
CREATE TABLE IF NOT EXISTS public.ai_memories (
    id UUID PRIMARY KEY,
    person_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    summary TEXT,
    tags TEXT,
    source_image_url TEXT,
    source_route TEXT,
    source_kind TEXT DEFAULT 'in_app',
    ai_model TEXT,
    -- draft rows are never injected into AI prompts; only 'confirmed' is.
    status TEXT NOT NULL DEFAULT 'draft',
    memory_weight REAL DEFAULT 1.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ai_memories_person_id_idx ON public.ai_memories (person_id);
CREATE INDEX IF NOT EXISTS ai_memories_person_status_idx ON public.ai_memories (person_id, status);

ALTER TABLE public.ai_memories ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ai_memories'
      AND policyname = 'Users can manage their own ai memories'
  ) THEN
    CREATE POLICY "Users can manage their own ai memories" ON public.ai_memories
      FOR ALL
      TO authenticated
      USING (auth.uid() = person_id)
      WITH CHECK (auth.uid() = person_id);
  END IF;
END $$;

-- Local queue of pending screen captures awaiting upload + extraction.
CREATE TABLE IF NOT EXISTS public.capture_queue (
    id UUID PRIMARY KEY,
    person_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    source_kind TEXT NOT NULL,
    app_label TEXT NOT NULL,
    route TEXT,
    image_url TEXT,
    score REAL NOT NULL DEFAULT 0.0,
    -- JSON array of scoring signals, for "why was this captured?".
    score_reasons TEXT,
    -- pending / uploading / analyzed / failed
    status TEXT NOT NULL DEFAULT 'pending',
    attempts INTEGER NOT NULL DEFAULT 0,
    error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS capture_queue_person_id_idx ON public.capture_queue (person_id);
CREATE INDEX IF NOT EXISTS capture_queue_person_status_idx ON public.capture_queue (person_id, status);

ALTER TABLE public.capture_queue ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'capture_queue'
      AND policyname = 'Users can manage their own capture queue'
  ) THEN
    CREATE POLICY "Users can manage their own capture queue" ON public.capture_queue
      FOR ALL
      TO authenticated
      USING (auth.uid() = person_id)
      WITH CHECK (auth.uid() = person_id);
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
