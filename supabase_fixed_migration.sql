-- Fixed migration to handle policy dependencies when altering column types
-- Run this in your Supabase SQL Editor

-- ==========================================
-- 1. FIX PROJECT_NOTES TABLE - SAFE APPROACH
-- ==========================================

-- Step 1: Drop existing policies that depend on columns we need to alter
DO $$
BEGIN
    -- Drop policies for project_notes
    EXECUTE 'DROP POLICY IF EXISTS "Users can read own notes" ON public.project_notes';
    EXECUTE 'DROP POLICY IF EXISTS "Users can insert own notes" ON public.project_notes';
    EXECUTE 'DROP POLICY IF EXISTS "Users can update own notes" ON public.project_notes';
    EXECUTE 'DROP POLICY IF EXISTS "Users can delete own notes" ON public.project_notes';
    
    -- Drop policies for mind_logs if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mind_logs' AND table_schema = 'public') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Users can read own mind logs" ON public.mind_logs';
        EXECUTE 'DROP POLICY IF EXISTS "Users can insert own mind logs" ON public.mind_logs';
        EXECUTE 'DROP POLICY IF EXISTS "Users can update own mind logs" ON public.mind_logs';
        EXECUTE 'DROP POLICY IF EXISTS "Users can delete own mind logs" ON public.mind_logs';
    END IF;
END $$;

-- Step 2: Add missing columns to project_notes (if they don't exist)
ALTER TABLE public.project_notes 
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS note_id text,
    ADD COLUMN IF NOT EXISTS category text DEFAULT 'projects',
    ADD COLUMN IF NOT EXISTS mood text;

-- Step 3: Safely alter column types only if needed
-- Check current types first and only convert if they're not already uuid
DO $$
DECLARE
    person_id_type text;
    project_id_type text;
BEGIN
    SELECT data_type INTO person_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'project_notes' AND column_name = 'person_id';
    
    SELECT data_type INTO project_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'project_notes' AND column_name = 'project_id';
    
    -- Only convert if not already uuid
    IF person_id_type != 'uuid' THEN
        EXECUTE 'ALTER TABLE public.project_notes ALTER COLUMN person_id TYPE uuid USING person_id::uuid';
    END IF;
    
    IF project_id_type != 'uuid' THEN
        EXECUTE 'ALTER TABLE public.project_notes ALTER COLUMN project_id TYPE uuid USING project_id::uuid';
    END IF;
END $$;

-- Step 4: Set note_id to match id for existing records (where note_id is null)
UPDATE public.project_notes SET note_id = id::text WHERE note_id IS NULL;

-- Step 5: Ensure mind_logs table exists with correct structure (matching PowerSync text expectations)
CREATE TABLE IF NOT EXISTS public.mind_logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    tenant_id text,
    person_id text,
    mood_score integer NOT NULL,
    mood_emoji text,
    activities text DEFAULT '[]',
    note text,
    log_date text,
    created_at text,
    CONSTRAINT mind_logs_pkey PRIMARY KEY (id)
);

-- Add missing columns to mind_logs if table already exists (with correct text types)
ALTER TABLE public.mind_logs 
    ADD COLUMN IF NOT EXISTS tenant_id text,
    ADD COLUMN IF NOT EXISTS person_id text,
    ADD COLUMN IF NOT EXISTS mood_emoji text,
    ADD COLUMN IF NOT EXISTS activities text DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS note text,
    ADD COLUMN IF NOT EXISTS log_date text,
    ADD COLUMN IF NOT EXISTS created_at text;

-- Convert existing column types to text if they're not already text
DO $$
DECLARE
    column_type text;
BEGIN
    -- Convert tenant_id to text if needed
    SELECT data_type INTO column_type 
    FROM information_schema.columns 
    WHERE table_name = 'mind_logs' AND column_name = 'tenant_id';
    IF column_type != 'text' THEN
        EXECUTE 'ALTER TABLE public.mind_logs ALTER COLUMN tenant_id TYPE text USING tenant_id::text';
    END IF;
    
    -- Convert person_id to text if needed
    SELECT data_type INTO column_type 
    FROM information_schema.columns 
    WHERE table_name = 'mind_logs' AND column_name = 'person_id';
    IF column_type != 'text' THEN
        EXECUTE 'ALTER TABLE public.mind_logs ALTER COLUMN person_id TYPE text USING person_id::text';
    END IF;
    
    -- Convert activities to text if needed (handle jsonb to text conversion)
    SELECT data_type INTO column_type 
    FROM information_schema.columns 
    WHERE table_name = 'mind_logs' AND column_name = 'activities';
    IF column_type != 'text' THEN
        EXECUTE 'ALTER TABLE public.mind_logs ALTER COLUMN activities TYPE text USING activities::text';
    END IF;
    
    -- Convert log_date to text if needed
    SELECT data_type INTO column_type 
    FROM information_schema.columns 
    WHERE table_name = 'mind_logs' AND column_name = 'log_date';
    IF column_type != 'text' THEN
        EXECUTE 'ALTER TABLE public.mind_logs ALTER COLUMN log_date TYPE text USING log_date::text';
    END IF;
    
    -- Convert created_at to text if needed
    SELECT data_type INTO column_type 
    FROM information_schema.columns 
    WHERE table_name = 'mind_logs' AND column_name = 'created_at';
    IF column_type != 'text' THEN
        EXECUTE 'ALTER TABLE public.mind_logs ALTER COLUMN created_at TYPE text USING created_at::text';
    END IF;
END $$;

-- Step 6: Enable Row Level Security on both tables
ALTER TABLE public.project_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mind_logs ENABLE ROW LEVEL SECURITY;

-- Step 7: Recreate policies for project_notes
CREATE POLICY "Users can read own notes" ON public.project_notes
    FOR SELECT
    USING (person_id = auth.uid());

CREATE POLICY "Users can insert own notes" ON public.project_notes
    FOR INSERT
    WITH CHECK (person_id = auth.uid());

CREATE POLICY "Users can update own notes" ON public.project_notes
    FOR UPDATE
    USING (person_id = auth.uid());

CREATE POLICY "Users can delete own notes" ON public.project_notes
    FOR DELETE
    USING (person_id = auth.uid());

-- Step 8: Recreate policies for mind_logs
CREATE POLICY "Users can read own mind logs" ON public.mind_logs
    FOR SELECT
    USING (person_id = auth.uid());

CREATE POLICY "Users can insert own mind logs" ON public.mind_logs
    FOR INSERT
    WITH CHECK (person_id = auth.uid());

CREATE POLICY "Users can update own mind logs" ON public.mind_logs
    FOR UPDATE
    USING (person_id = auth.uid());

CREATE POLICY "Users can delete own mind logs" ON public.mind_logs
    FOR DELETE
    USING (person_id = auth.uid());

-- ==========================================
-- 2. VERIFICATION
-- ==========================================

-- Verify project_notes structure
SELECT 'project_notes' as table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'project_notes'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify mind_logs structure
SELECT 'mind_logs' as table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'mind_logs'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify RLS is enabled
SELECT relname as table_name, relrowsecurity as rls_enabled
FROM pg_class
WHERE relname IN ('project_notes', 'mind_logs')
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Verify policies exist
SELECT 
    tablename as table_name,
    policyname,
    cmd,
    permissive
FROM pg_policies
WHERE tablename IN ('project_notes', 'mind_logs')
AND schemaname = 'public'
ORDER BY tablename, policyname;