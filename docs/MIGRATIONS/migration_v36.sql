-- Migration v36: Add cover_image_url to profile-related tables
-- Run this in Supabase SQL Editor

-- 1. Add cover_image_url to persons table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'cover_image_url') THEN
        ALTER TABLE public.persons ADD COLUMN cover_image_url text;
    END IF;
END $$;

-- 2. Add cover_image_url to profiles table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'cover_image_url') THEN
        ALTER TABLE public.profiles ADD COLUMN cover_image_url text;
    END IF;
END $$;

-- 3. Add cover_image_url to detail_information table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'detail_information' AND column_name = 'cover_image_url') THEN
        ALTER TABLE public.detail_information ADD COLUMN cover_image_url text;
    END IF;
END $$;

-- 4. Refresh PowerSync Publication
-- PowerSync works by tracking changes in the 'powersync' publication.
-- If the publication is for ALL TABLES, it might pick up schema changes automatically,
-- but sometimes a refresh or re-run of the publication script is needed.
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR ALL TABLES;
