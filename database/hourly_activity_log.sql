-- Migration to add hourly_activity_log table for step tracking
-- This matches the Drift definition in Database.dart

CREATE TABLE IF NOT EXISTS public.hourly_activity_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid REFERENCES public.persons(id) ON DELETE CASCADE,
    start_time timestamptz NOT NULL,
    end_time timestamptz,
    log_date date NOT NULL DEFAULT CURRENT_DATE,
    steps_count integer DEFAULT 0,
    distance_km double precision DEFAULT 0.0,
    calories_burned integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.hourly_activity_log ENABLE ROW LEVEL SECURITY;

-- Add RLS policy: users can only see and modify their own data
DROP POLICY IF EXISTS "Users can manage their own hourly activity logs" ON public.hourly_activity_log;
CREATE POLICY "Users can manage their own hourly activity logs"
ON public.hourly_activity_log
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);

-- Add the table to the PowerSync publication
-- This ensures PowerSync can watch this table for changes.
-- Note: If you get an error here, it might be because the table is already in the publication.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'powersync' AND tablename = 'hourly_activity_log'
    ) THEN
        NULL;
    ELSE
        ALTER PUBLICATION powersync ADD TABLE public.hourly_activity_log;
    END IF;
END $$;
