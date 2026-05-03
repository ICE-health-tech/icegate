-- Synced custom labels for journal mood activity chips (referenced from mind_logs.activities as act_user_ref:<id>)

CREATE TABLE IF NOT EXISTS public.journal_activity_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id TEXT,
    person_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_key TEXT NOT NULL,
    label TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS journal_activity_options_person_id_idx
    ON public.journal_activity_options (person_id);

ALTER TABLE public.journal_activity_options ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'journal_activity_options'
          AND policyname = 'Users manage own journal activity options'
    ) THEN
        CREATE POLICY "Users manage own journal activity options"
            ON public.journal_activity_options
            FOR ALL
            USING (auth.uid() = person_id)
            WITH CHECK (auth.uid() = person_id);
    END IF;
END $$;

NOTIFY pgrst, 'reload schema';
