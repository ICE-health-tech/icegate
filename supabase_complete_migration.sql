-- Complete migration to fix schema issues preventing data fetch
-- Run this in your Supabase SQL Editor
-- This migration fixes both project_notes and mind_logs tables

-- ==========================================
-- 1. FIX PROJECT_NOTES TABLE
-- ==========================================

-- Add missing columns to project_notes
ALTER TABLE public.project_notes 
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS note_id text,
    ADD COLUMN IF NOT EXISTS category text DEFAULT 'projects',
    ADD COLUMN IF NOT EXISTS mood text;

-- Ensure person_id and project_id are UUID type
-- (Only run these if your columns are still integers)
ALTER TABLE public.project_notes 
    ALTER COLUMN person_id TYPE uuid USING person_id::uuid,
    ALTER COLUMN project_id TYPE uuid USING project_id::uuid;

-- Set note_id to match id for existing records
UPDATE public.project_notes SET note_id = id::text WHERE note_id IS NULL;

-- ==========================================
-- 2. ENSURE MIND_LOGS TABLE EXISTS
-- ==========================================

-- Create mind_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.mind_logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    tenant_id uuid,
    person_id uuid,
    mood_score integer NOT NULL,
    mood_emoji text,
    activities jsonb DEFAULT '[]'::jsonb,
    note text,
    log_date date DEFAULT CURRENT_DATE,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT mind_logs_pkey PRIMARY KEY (id),
    CONSTRAINT mind_logs_person_id_fkey FOREIGN KEY (person_id) REFERENCES persons(id)
) TABLESPACE pg_default;

-- Add missing columns to mind_logs if table already exists
ALTER TABLE public.mind_logs 
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS mood_emoji text,
    ADD COLUMN IF NOT EXISTS activities jsonb DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS note text,
    ADD COLUMN IF NOT EXISTS log_date date DEFAULT CURRENT_DATE;

-- ==========================================
-- 3. ENABLE ROW LEVEL SECURITY AND CREATE POLICIES
-- ==========================================

-- Enable RLS on both tables
ALTER TABLE public.project_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mind_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (if any) and create new ones for project_notes
DROP POLICY IF EXISTS "Users can read own project notes" ON public.project_notes;
DROP POLICY IF EXISTS "Users can insert own project notes" ON public.project_notes;
DROP POLICY IF EXISTS "Users can update own project notes" ON public.project_notes;
DROP POLICY IF EXISTS "Users can delete own project notes" ON public.project_notes;

CREATE POLICY "Users can read own project notes" ON public.project_notes
    FOR SELECT
    USING (person_id = auth.uid());

CREATE POLICY "Users can insert own project notes" ON public.project_notes
    FOR INSERT
    WITH CHECK (person_id = auth.uid());

CREATE POLICY "Users can update own project notes" ON public.project_notes
    FOR UPDATE
    USING (person_id = auth.uid());

CREATE POLICY "Users can delete own project notes" ON public.project_notes
    FOR DELETE
    USING (person_id = auth.uid());

-- Drop existing policies (if any) and create new ones for mind_logs
DROP POLICY IF EXISTS "Users can read own mind logs" ON public.mind_logs;
DROP POLICY IF EXISTS "Users can insert own mind logs" ON public.mind_logs;
DROP POLICY IF EXISTS "Users can update own mind logs" ON public.mind_logs;
DROP POLICY IF EXISTS "Users can delete own mind logs" ON public.mind_logs;

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
-- 4. VERIFICATION
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