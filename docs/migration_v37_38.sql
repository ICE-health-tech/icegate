-- Migration to add cover_image_url to persons, profiles, and cv_addresses
-- Drift Schema Version: 37 (initial addition)
-- Applied to Supabase PostgreSQL
ALTER TABLE IF EXISTS public.persons
ADD COLUMN IF NOT EXISTS cover_image_url TEXT,
ADD COLUMN IF NOT EXISTS avatar_local_path TEXT,
ADD COLUMN IF NOT EXISTS cover_local_path TEXT;

ALTER TABLE IF EXISTS public.profiles
ADD COLUMN IF NOT EXISTS cover_image_url TEXT,
ADD COLUMN IF NOT EXISTS avatar_local_path TEXT,
ADD COLUMN IF NOT EXISTS cover_local_path TEXT;

ALTER TABLE IF EXISTS public.cv_addresses
ADD COLUMN IF NOT EXISTS cover_image_url TEXT,
ADD COLUMN IF NOT EXISTS avatar_local_path TEXT,
ADD COLUMN IF NOT EXISTS cover_local_path TEXT;

COMMENT ON COLUMN public.persons.cover_image_url IS 'URL for the user profile cover image';

COMMENT ON COLUMN public.profiles.cover_image_url IS 'URL for the user profile cover image (redundant/cached)';