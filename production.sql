-- =====================================================
-- Ice Shield: FULL Supabase Schema Reset
-- This drops and recreates ALL app tables with the 
-- correct snake_case columns matching PowerSync/Drift.
-- =====================================================
-- ⚠️ WARNING: This will DELETE all data in these tables!
-- The persons table is NOT dropped (only fixed in-place)
-- to preserve auth trigger linkage.
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 1. FIX PERSONS IN-PLACE (don't drop — auth trigger depends on it)
-- ==========================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'createdAt') THEN
        ALTER TABLE public.persons RENAME COLUMN "createdAt" TO created_at;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'updatedAt') THEN
        ALTER TABLE public.persons RENAME COLUMN "updatedAt" TO updated_at;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'personID') THEN
        ALTER TABLE public.persons RENAME COLUMN "personID" TO person_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'created_at') THEN
        ALTER TABLE public.persons ADD COLUMN created_at text DEFAULT CURRENT_TIMESTAMP::text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'persons' AND column_name = 'updated_at') THEN
        ALTER TABLE public.persons ADD COLUMN updated_at text DEFAULT CURRENT_TIMESTAMP::text;
    END IF;
END $$;

-- ==========================================
-- 2. DROP AND RECREATE ALL OTHER TABLES
-- ==========================================

-- email_addresses
DROP TABLE IF EXISTS public.email_addresses CASCADE;
CREATE TABLE email_addresses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    email_address text,
    email_type text DEFAULT 'personal',
    is_primary boolean DEFAULT false,
    status text DEFAULT 'pending',
    verified_at text,
    created_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- profiles
DROP TABLE IF EXISTS public.profiles CASCADE;
CREATE TABLE profiles (
    id uuid PRIMARY KEY,
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

-- projects
DROP TABLE IF EXISTS public.projects CASCADE;
CREATE TABLE projects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id SERIAL UNIQUE,
    person_id integer,
    name text,
    description text,
    category text,
    color text,
    status integer DEFAULT 0,
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- project_notes
DROP TABLE IF EXISTS public.project_notes CASCADE;
CREATE TABLE project_notes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    title text,
    content text,
    created_at text,
    updated_at text,
    project_id integer
);

-- financial_accounts
DROP TABLE IF EXISTS public.financial_accounts CASCADE;
CREATE TABLE financial_accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    account_name text,
    account_type text DEFAULT 'checking',
    balance double precision DEFAULT 0.0,
    currency text DEFAULT 'USD',
    is_primary integer DEFAULT 0,
    is_active integer DEFAULT 1,
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- assets
DROP TABLE IF EXISTS public.assets CASCADE;
CREATE TABLE assets (
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- transactions
DROP TABLE IF EXISTS public.transactions CASCADE;
CREATE TABLE transactions (
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

-- health_metrics
DROP TABLE IF EXISTS public.health_metrics CASCADE;
CREATE TABLE health_metrics (
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

-- meals
DROP TABLE IF EXISTS public.meals CASCADE;
CREATE TABLE meals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_name text,
    meal_image_url text,
    fat double precision DEFAULT 0.0,
    carbs double precision DEFAULT 0.0,
    protein double precision DEFAULT 0.0,
    calories double precision DEFAULT 0.0,
    eaten_at text
);

-- days
DROP TABLE IF EXISTS public.days CASCADE;
CREATE TABLE days (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    day_id text,
    weight integer DEFAULT 0,
    calories_out integer DEFAULT 0
);

-- water_logs
DROP TABLE IF EXISTS public.water_logs CASCADE;
CREATE TABLE water_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    amount integer DEFAULT 0,
    "timestamp" text
);

-- sleep_logs
DROP TABLE IF EXISTS public.sleep_logs CASCADE;
CREATE TABLE sleep_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    start_time text,
    end_time text,
    quality integer DEFAULT 3
);

-- exercise_logs
DROP TABLE IF EXISTS public.exercise_logs CASCADE;
CREATE TABLE exercise_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    type text,
    duration_minutes integer,
    intensity text DEFAULT 'medium',
    "timestamp" text
);

-- internal_widgets
DROP TABLE IF EXISTS public.internal_widgets CASCADE;
CREATE TABLE internal_widgets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    widget_id integer,
    name text,
    url text,
    date_added text,
    image_url text,
    alias text
);

-- external_widgets
DROP TABLE IF EXISTS public.external_widgets CASCADE;
CREATE TABLE external_widgets (
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

-- themes
DROP TABLE IF EXISTS public.themes CASCADE;
CREATE TABLE themes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id SERIAL UNIQUE,
    name text,
    alias text,
    json_content text,
    author text,
    added_date text
);

-- user_accounts
DROP TABLE IF EXISTS public.user_accounts CASCADE;
CREATE TABLE user_accounts (
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- detail_information
DROP TABLE IF EXISTS public.detail_information CASCADE;
CREATE TABLE detail_information (
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- skills
DROP TABLE IF EXISTS public.skills CASCADE;
CREATE TABLE skills (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    skill_id SERIAL UNIQUE,
    person_id integer,
    skill_name text,
    skill_category text,
    proficiency_level text DEFAULT 'beginner',
    years_of_experience integer DEFAULT 0,
    description text,
    is_featured integer DEFAULT 0,
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- goals
DROP TABLE IF EXISTS public.goals CASCADE;
CREATE TABLE goals (
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text,
    project_id integer
);

-- scores
DROP TABLE IF EXISTS public.scores CASCADE;
CREATE TABLE scores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    score_id SERIAL UNIQUE,
    person_id integer UNIQUE,
    health_global_score double precision DEFAULT 0.0,
    social_global_score double precision DEFAULT 0.0,
    financial_global_score double precision DEFAULT 0.0,
    career_global_score double precision DEFAULT 0.0,
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- habits
DROP TABLE IF EXISTS public.habits CASCADE;
CREATE TABLE habits (
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- blog_posts
DROP TABLE IF EXISTS public.blog_posts CASCADE;
CREATE TABLE blog_posts (
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- person_widgets
DROP TABLE IF EXISTS public.person_widgets CASCADE;
CREATE TABLE person_widgets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_widget_id SERIAL UNIQUE,
    person_id integer,
    widget_name text,
    widget_type text,
    configuration text DEFAULT '{}',
    display_order integer DEFAULT 0,
    is_active integer DEFAULT 1,
    role text DEFAULT 'admin',
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- sessions
DROP TABLE IF EXISTS public.sessions CASCADE;
CREATE TABLE sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id SERIAL UNIQUE,
    jwt text,
    username text,
    created_at text
);

-- themes_config
DROP TABLE IF EXISTS public.themes_config CASCADE;
CREATE TABLE themes_config (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id SERIAL UNIQUE,
    theme_name text,
    theme_path text
);

-- focus_sessions
DROP TABLE IF EXISTS public.focus_sessions CASCADE;
CREATE TABLE focus_sessions (
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

-- custom_notifications
DROP TABLE IF EXISTS public.custom_notifications CASCADE;
CREATE TABLE custom_notifications (
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

-- quotes
DROP TABLE IF EXISTS public.quotes CASCADE;
CREATE TABLE quotes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id SERIAL UNIQUE,
    content text,
    author text,
    is_active integer DEFAULT 1,
    created_at text
);

-- quests
DROP TABLE IF EXISTS public.quests CASCADE;
CREATE TABLE quests (
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

-- health_logs
DROP TABLE IF EXISTS public.health_logs CASCADE;
CREATE TABLE health_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id integer,
    log_type text,
    value double precision DEFAULT 0.0,
    unit text,
    logged_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- ==========================================
-- 3. ENABLE RLS FOR ALL TABLES
-- ==========================================
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

-- ==========================================
-- 4. REFRESH POWERSYNC PUBLICATION
-- ==========================================
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR ALL TABLES;
