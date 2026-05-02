-- Per-user AI / LLM prompt text (local app syncs via Drift + Supabase)
CREATE TABLE IF NOT EXISTS public.ai_prompts (
    id UUID PRIMARY KEY,
    person_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    ai_model TEXT NOT NULL,
    prompt TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ai_prompts_person_id_idx ON public.ai_prompts (person_id);

ALTER TABLE public.ai_prompts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'ai_prompts'
      AND policyname = 'Users can manage their own ai prompts'
  ) THEN
    CREATE POLICY "Users can manage their own ai prompts" ON public.ai_prompts
      FOR ALL
      TO authenticated
      USING (auth.uid() = person_id)
      WITH CHECK (auth.uid() = person_id);
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
