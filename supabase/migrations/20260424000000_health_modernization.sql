-- Migration: Health Modernization
-- Adds heart_rate_logs table and missing columns to health_metrics

-- 1. Create the heart_rate_logs table
CREATE TABLE IF NOT EXISTS public.heart_rate_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    person_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    bpm INTEGER NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add missing columns to health_metrics if they don't exist
ALTER TABLE public.health_metrics 
ADD COLUMN IF NOT EXISTS oxygen_saturation FLOAT,
ADD COLUMN IF NOT EXISTS exercise_minutes INTEGER,
ADD COLUMN IF NOT EXISTS focus_minutes INTEGER;

-- 3. Enable RLS and set policies for heart_rate_logs
ALTER TABLE public.heart_rate_logs ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'heart_rate_logs' AND policyname = 'Users can manage their own heart rate logs'
    ) THEN
        CREATE POLICY "Users can manage their own heart rate logs" 
        ON public.heart_rate_logs 
        FOR ALL 
        USING (auth.uid() = person_id);
    END IF;
END $$;

-- 4. Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
