-- Supabase SQL Schema for Ice Shield (Full Rebuild & Fix)
-- Aligned with Drift Database.dart and PowerSync powersync_schema.dart

-- ==========================================
-- 0. CLEANUP (Run this if you have existing tables to ensure clean state)
-- ==========================================
-- DROP TABLE IF EXISTS public.persons CASCADE;
-- DROP TABLE IF EXISTS public.email_addresses CASCADE;
-- DROP TABLE IF EXISTS public.profiles CASCADE;
-- ... (and others)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 1. IDENTITY & USER TABLES
-- ==========================================

-- 1. persons
CREATE TABLE IF NOT EXISTS persons (
    id uuid PRIMARY KEY, -- Matches auth.users.id for Google users
    person_id SERIAL UNIQUE, -- Matching Drift property name for legacy references
    first_name text,
    last_name text,
    date_of_birth text,
    gender text,
    phone_number text,
    profile_image_url text,
    relationship text DEFAULT 'none',
    affection integer DEFAULT 0,
    is_active integer DEFAULT 1,
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- 2. email_addresses
CREATE TABLE IF NOT EXISTS email_addresses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer, -- References persons("personID")
    email_address text,
    email_type text DEFAULT 'personal',
    is_primary integer DEFAULT 0,
    status text DEFAULT 'pending',
    verified_at text,
    created_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- 3. profiles
CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY, -- Matches auth.users.id
    person_id integer UNIQUE,
    bio text,
    occupation text,
    education_level text,
    location text,
    website_url text,
    linkedin_url text,
    github_url text,
    timezone text DEFAULT 'UTC',
    preferred_language text DEFAULT 'en',
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- 4. Auth Sync Function & Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  new_person_serial int;
BEGIN
  -- Insert into persons (use UUID as ID)
  INSERT INTO public.persons (id, first_name, last_name, profile_image_url, is_active)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'IceUser'),
    COALESCE(new.raw_user_meta_data->>'family_name', ''),
    new.raw_user_meta_data->>'avatar_url',
    1
  )
  ON CONFLICT (id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    profile_image_url = EXCLUDED.profile_image_url,
    updated_at = CURRENT_TIMESTAMP::text
  RETURNING person_id INTO new_person_serial;

  -- Insert into email_addresses
  INSERT INTO public.email_addresses (id, person_id, email_address, is_primary, status)
  VALUES (
    gen_random_uuid(),
    new_person_serial,
    new.email,
    1,
    'verified'
  )
  ON CONFLICT DO NOTHING;

  -- Insert into profiles
  INSERT INTO public.profiles (id, person_id, bio)
  VALUES (
    new.id,
    new_person_serial,
    COALESCE(new.raw_user_meta_data->>'bio', 'Securing the digital frontier.')
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated AFTER UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- 2. PROJECT & NOTES TABLES
-- ==========================================

CREATE TABLE IF NOT EXISTS projects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    name text,
    description text,
    category text,
    color text,
    status integer DEFAULT 0,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS project_notes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    title text,
    content text,
    created_at text,
    updated_at text,
    project_id integer
);

-- ==========================================
-- 3. FINANCE TABLES
-- ==========================================

CREATE TABLE IF NOT EXISTS financial_accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    account_name text,
    account_type text DEFAULT 'checking',
    balance double precision DEFAULT 0.0,
    currency text DEFAULT 'USD',
    is_primary integer DEFAULT 0,
    is_active integer DEFAULT 1,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS assets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    asset_name text,
    asset_category text,
    purchase_date text,
    purchase_price double precision,
    current_estimated_value double precision,
    currency text DEFAULT 'USD',
    condition text DEFAULT 'good',
    location text,
    notes text,
    is_insured integer DEFAULT 0,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    category text,
    type text,
    amount double precision,
    description text,
    transaction_date text,
    created_at text,
    project_id integer
);

-- ==========================================
-- 4. HEALTH & DAILY TABLES
-- ==========================================

CREATE TABLE IF NOT EXISTS health_metrics (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    date text,
    steps integer DEFAULT 0,
    heart_rate integer DEFAULT 0,
    sleep_hours double precision DEFAULT 0.0,
    water_glasses integer DEFAULT 0,
    exercise_minutes integer DEFAULT 0,
    focus_minutes integer DEFAULT 0,
    weight_kg double precision DEFAULT 0.0,
    calories_consumed integer DEFAULT 0,
    calories_burned integer DEFAULT 0,
    updated_at text
);

CREATE TABLE IF NOT EXISTS meals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_name text,
    meal_image_url text,
    fat double precision DEFAULT 0.0,
    carbs double precision DEFAULT 0.0,
    protein double precision DEFAULT 0.0,
    calories double precision DEFAULT 0.0,
    eaten_at text
);

CREATE TABLE IF NOT EXISTS days (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    day_id text,
    weight integer DEFAULT 0,
    calories_out integer DEFAULT 0
);

CREATE TABLE IF NOT EXISTS water_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    amount integer DEFAULT 0,
    "timestamp" text
);

CREATE TABLE IF NOT EXISTS sleep_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    start_time text,
    end_time text,
    quality integer DEFAULT 3
);

CREATE TABLE IF NOT EXISTS exercise_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    type text,
    duration_minutes integer,
    intensity text DEFAULT 'medium',
    "timestamp" text
);

-- ==========================================
-- 5. OTHER UTILITY TABLES
-- ==========================================

CREATE TABLE IF NOT EXISTS internal_widgets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    widget_id integer,
    name text,
    url text,
    date_added text,
    image_url text,
    alias text
);

CREATE TABLE IF NOT EXISTS external_widgets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    widget_id integer,
    name text,
    alias text,
    protocol text,
    host text,
    url text,
    image_url text,
    date_added text
);

CREATE TABLE IF NOT EXISTS themes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id integer,
    name text,
    alias text,
    json_content text,
    author text,
    added_date text
);

CREATE TABLE IF NOT EXISTS user_accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    username text UNIQUE,
    password_hash text,
    primary_email_id integer,
    role text DEFAULT 'user',
    is_locked integer DEFAULT 0,
    failed_login_attempts integer DEFAULT 0,
    last_login_at text,
    password_changed_at text,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS detail_information (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    cv_address_id SERIAL UNIQUE,
    person_id integer UNIQUE,
    github_url text,
    website_url text,
    company text,
    university text,
    location text,
    country text,
    bio text,
    occupation text,
    education_level text,
    linkedin_url text,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS skills (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_id SERIAL UNIQUE,
    person_id integer,
    skill_name text,
    skill_category text,
    proficiency_level text DEFAULT 'beginner',
    years_of_experience integer DEFAULT 0,
    description text,
    is_featured integer DEFAULT 0,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS goals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id SERIAL UNIQUE,
    person_id integer,
    title text,
    description text,
    category text DEFAULT 'personal',
    priority integer DEFAULT 3,
    status text DEFAULT 'active',
    target_date text,
    completion_date text,
    progress_percentage integer DEFAULT 0,
    created_at text,
    updated_at text,
    project_id integer
);

CREATE TABLE IF NOT EXISTS scores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    score_id SERIAL UNIQUE,
    person_id integer UNIQUE,
    health_global_score double precision DEFAULT 0.0,
    social_global_score double precision DEFAULT 0.0,
    financial_global_score double precision DEFAULT 0.0,
    career_global_score double precision DEFAULT 0.0,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS habits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id SERIAL UNIQUE,
    person_id integer,
    goal_id integer,
    habit_name text,
    description text,
    frequency text,
    frequency_details text,
    target_count integer DEFAULT 1,
    is_active integer DEFAULT 1,
    started_date text,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS blog_posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id SERIAL UNIQUE,
    author_id integer,
    title text,
    slug text UNIQUE,
    excerpt text,
    content text,
    featured_image_url text,
    status text DEFAULT 'draft',
    is_featured integer DEFAULT 0,
    view_count integer DEFAULT 0,
    like_count integer DEFAULT 0,
    published_at text,
    scheduled_for text,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS person_widgets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_widget_id SERIAL UNIQUE,
    person_id integer,
    widget_name text,
    widget_type text,
    configuration text DEFAULT '{}',
    display_order integer DEFAULT 0,
    is_active integer DEFAULT 1,
    role text DEFAULT 'admin',
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id SERIAL UNIQUE,
    jwt text,
    username text,
    created_at text
);

CREATE TABLE IF NOT EXISTS themes_config (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id SERIAL UNIQUE,
    theme_name text,
    theme_path text
);

CREATE TABLE IF NOT EXISTS focus_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id SERIAL UNIQUE,
    person_id integer,
    project_id integer,
    start_time text,
    end_time text,
    duration_seconds integer,
    status text,
    task_id integer,
    notes text
);

CREATE TABLE IF NOT EXISTS custom_notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id SERIAL UNIQUE,
    title text,
    content text,
    scheduled_time text,
    repeat_frequency text DEFAULT 'none',
    repeat_days text,
    is_enabled integer DEFAULT 1,
    created_at text
);

CREATE TABLE IF NOT EXISTS quotes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id SERIAL UNIQUE,
    content text,
    author text,
    is_active integer DEFAULT 1,
    created_at text
);

CREATE TABLE IF NOT EXISTS quests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quest_id SERIAL UNIQUE,
    title text,
    description text,
    type text DEFAULT 'daily',
    target_value double precision DEFAULT 0.0,
    current_value double precision DEFAULT 0.0,
    category text DEFAULT 'health',
    reward_exp integer DEFAULT 10,
    is_completed integer DEFAULT 0,
    created_at text
);

-- ==========================================
-- 6. POWERSYNC & RLS CONFIGURATION
-- ==========================================

-- Create Publication for PowerSync
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR ALL TABLES;

-- Enable RLS and add basic policies
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS "Permissive Policy" ON public.%I', t);
        EXECUTE format('CREATE POLICY "Permissive Policy" ON public.%I FOR ALL USING (true) WITH CHECK (true)', t);
    END LOOP;
END $$;
