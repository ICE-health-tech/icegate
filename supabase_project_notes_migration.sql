-- Migration to fix project_notes table schema for PowerSync compatibility
-- Run this in your Supabase SQL Editor

-- Drop existing table and recreate with correct schema
-- WARNING: This will delete all existing journal/social notes data!
-- Only run this in development or if you have backed up your data!

DROP TABLE IF EXISTS public.project_notes CASCADE;

CREATE TABLE public.project_notes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    tenant_id uuid,
    note_id text,
    person_id uuid,
    title text NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone NULL DEFAULT now(),
    updated_at timestamp with time zone NULL DEFAULT now(),
    project_id uuid,
    category text NULL DEFAULT 'projects'::text,
    mood text,
    CONSTRAINT project_notes_pkey PRIMARY KEY (id),
    CONSTRAINT project_notes_person_id_fkey FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE,
    CONSTRAINT project_notes_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    CONSTRAINT project_notes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES organizations(id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Enable Row Level Security
ALTER TABLE public.project_notes ENABLE ROW LEVEL SECURITY;

-- Create policies for user access
-- Users can only see and modify their own notes

-- Policy for SELECT (reading notes)
CREATE POLICY "Users can read own notes" ON public.project_notes
    FOR SELECT
    USING (person_id = auth.uid());

-- Policy for INSERT (creating notes)
CREATE POLICY "Users can insert own notes" ON public.project_notes
    FOR INSERT
    WITH CHECK (person_id = auth.uid());

-- Policy for UPDATE (modifying notes)
CREATE POLICY "Users can update own notes" ON public.project_notes
    FOR UPDATE
    USING (person_id = auth.uid());

-- Policy for DELETE (deleting notes)
CREATE POLICY "Users can delete own notes" ON public.project_notes
    FOR DELETE
    USING (person_id = auth.uid());

-- Optional: If you want to preserve existing data and just alter the table:
-- (Use this approach instead of DROP/CREATE if you have important data)

/*
ALTER TABLE public.project_notes 
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS note_id text,
    ADD COLUMN IF NOT EXISTS category text DEFAULT 'projects',
    ADD COLUMN IF NOT EXISTS mood text;

-- Convert existing integer IDs to UUID if needed
-- (Only run these if your person_id/project_id are still integers)
ALTER TABLE public.project_notes 
    ALTER COLUMN person_id TYPE uuid USING person_id::uuid,
    ALTER COLUMN project_id TYPE uuid USING project_id::uuid;

-- Set note_id to match id for existing records
UPDATE public.project_notes SET note_id = id::text WHERE note_id IS NULL;

-- Enable RLS if not already enabled
ALTER TABLE public.project_notes ENABLE ROW LEVEL SECURITY;

-- Add policies (drop existing ones first if needed)
DROP POLICY IF EXISTS "Users can read own notes" ON public.project_notes;
DROP POLICY IF EXISTS "Users can insert own notes" ON public.project_notes;
DROP POLICY IF EXISTS "Users can update own notes" ON public.project_notes;
DROP POLICY IF EXISTS "Users can delete own notes" ON public.project_notes;

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
*/

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'project_notes'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify RLS is enabled
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'project_notes'
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Verify policies
SELECT policyname, cmd, permissive, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'project_notes'
AND schemaname = 'public';