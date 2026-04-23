-- Migration v35: Add quests table and enforce lowercase categories
-- Run this in Supabase SQL Editor

-- 1. Create quests table if not exists (matching provided schema)
CREATE TABLE IF NOT EXISTS public.quests (
  id uuid NOT NULL,
  tenant_id uuid NULL,
  person_id text NULL,
  title text NOT NULL,
  description text NULL,
  type text NULL DEFAULT 'daily'::text,
  target_value real NULL DEFAULT 0.0,
  current_value real NULL DEFAULT 0.0,
  category text NULL DEFAULT 'health'::text,
  reward_exp integer NULL DEFAULT 10,
  is_completed boolean NULL DEFAULT false,
  created_at timestamp with time zone NULL DEFAULT now(),
  image_url text NULL,
  penalty_score integer NULL DEFAULT 0,
  CONSTRAINT quests_pkey PRIMARY KEY (id),
  CONSTRAINT quests_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES organizations (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- 2. Enforce lowercase for existing categories
UPDATE public.quests SET category = LOWER(category);

-- 3. Add constraint to ensure future categories are lowercase (Optional but recommended)
-- ALTER TABLE public.quests ADD CONSTRAINT quests_category_lowercase CHECK (category = LOWER(category));
