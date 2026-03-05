-- Migration v34: Add penalty_score to scores, person_id to quests/quotes
-- Run this in Supabase SQL Editor

-- 1. Add penalty_score to scores table
ALTER TABLE public.scores
ADD COLUMN IF NOT EXISTS penalty_score real DEFAULT 0.0;

-- 2. Add person_id to quests (if not already present from CREATE TABLE)
-- If quests was already recreated with the new schema, skip this.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quests' AND column_name = 'person_id'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN person_id text NULL;
  END IF;
END $$;

-- Remove old quest_id column if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quests' AND column_name = 'quest_id'
  ) THEN
    ALTER TABLE public.quests DROP COLUMN quest_id;
  END IF;
END $$;

-- 3. Add penalty_score to quests (if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quests' AND column_name = 'penalty_score'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN penalty_score integer DEFAULT 0;
  END IF;
END $$;

-- 4. Add person_id to quotes (if not already present)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quotes' AND column_name = 'person_id'
  ) THEN
    ALTER TABLE public.quotes ADD COLUMN person_id text NULL;
  END IF;
END $$;

-- Remove old quote_id column if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'quotes' AND column_name = 'quote_id'
  ) THEN
    ALTER TABLE public.quotes DROP COLUMN quote_id;
  END IF;
END $$;

-- 5. Add person_id to internal_widgets
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'internal_widgets' AND column_name = 'person_id'
  ) THEN
    ALTER TABLE public.internal_widgets ADD COLUMN person_id text NULL;
  END IF;
END $$;

-- 6. Add person_id to external_widgets
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'external_widgets' AND column_name = 'person_id'
  ) THEN
    ALTER TABLE public.external_widgets ADD COLUMN person_id text NULL;
  END IF;
END $$;
