-- Migration v45: Add missing columns for Quests and Profiles
-- This fixes the PGRST204 "Column not found" errors in PowerSync.

-- 1. Update quests table
ALTER TABLE public.quests
ADD COLUMN IF NOT EXISTS quest_type text,
ADD COLUMN IF NOT EXISTS penalty_score integer DEFAULT 0;

-- 2. Update profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS last_quest_generated_at timestamptz;

-- 3. Update scores table
ALTER TABLE public.scores
ADD COLUMN IF NOT EXISTS penalty_score real DEFAULT 0.0;

-- 4. Refresh PowerSync Publication
-- Ensure the new columns are included in the sync.
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR ALL TABLES;
