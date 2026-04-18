-- Migration to add mind_logs table for mental health tracking
-- Run this in your Supabase SQL Editor

-- Create the mind_logs table
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

-- Enable Row Level Security
ALTER TABLE public.mind_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for user access
-- Users can only see and modify their own mind logs

-- Policy for SELECT (reading mind logs)
CREATE POLICY "Users can read own mind logs" ON public.mind_logs
    FOR SELECT
    USING (person_id = auth.uid());

-- Policy for INSERT (creating mind logs)
CREATE POLICY "Users can insert own mind logs" ON public.mind_logs
    FOR INSERT
    WITH CHECK (person_id = auth.uid());

-- Policy for UPDATE (modifying mind logs)
CREATE POLICY "Users can update own mind logs" ON public.mind_logs
    FOR UPDATE
    USING (person_id = auth.uid());

-- Policy for DELETE (deleting mind logs)
CREATE POLICY "Users can delete own mind logs" ON public.mind_logs
    FOR DELETE
    USING (person_id = auth.uid());

-- Optional: If you want to just alter an existing table to add missing columns:
/*
ALTER TABLE public.mind_logs 
    ADD COLUMN IF NOT EXISTS tenant_id uuid,
    ADD COLUMN IF NOT EXISTS mood_emoji text,
    ADD COLUMN IF NOT EXISTS activities jsonb DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS note text,
    ADD COLUMN IF NOT EXISTS log_date date DEFAULT CURRENT_DATE;
*/

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'mind_logs'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify RLS is enabled
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'mind_logs'
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- Verify policies exist
SELECT policyname, cmd, permissive, roles, qual, with_check
FROM pg_policies
WHERE tablename = 'mind_logs'
AND schemaname = 'public';