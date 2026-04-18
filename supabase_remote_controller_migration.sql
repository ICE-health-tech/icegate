-- --------------------------------------------------------------------------------
-- REMOTE CONTROLLER SCHEMA 2026-04-18
-- Goal: Enable real-time remote commands via Supabase direct API (bypass PowerSync)
-- --------------------------------------------------------------------------------

-- 1. Create remote_commands table
CREATE TABLE IF NOT EXISTS public.remote_commands (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid REFERENCES public.persons(id) ON DELETE CASCADE,
    command text NOT NULL,                    -- e.g., 'PLAY_MUSIC', 'LOCK_APP', 'THEME_SWITCH'
    payload jsonb DEFAULT '{}'::jsonb,        -- e.g., { "track": "sounds/birds.mp3" }
    status text DEFAULT 'pending',             -- pending, acknowledged, completed, failed
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 2. Enable Row Level Security
ALTER TABLE public.remote_commands ENABLE ROW LEVEL SECURITY;

-- 3. Policies: Only owner can send/receive commands
CREATE POLICY "Users can manage their own remote commands"
ON public.remote_commands
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);

-- 4. Enable Realtime for this table
ALTER TABLE public.remote_commands REPLICA IDENTITY FULL;

-- If you have a custom publication for real-time:
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.remote_commands;

-- NOTE: Since PowerSync is NOT used for this feature, 
-- we do NOT add it to the 'powersync' publication.
