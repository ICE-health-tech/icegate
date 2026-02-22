-- =====================================================
-- Ice Shield: Snake Case Migration Script
-- Run this in Supabase SQL Editor to fix any 
-- tables that may have been created with camelCase.
-- =====================================================

-- 1. Drop and recreate SKILLS (had personID, skillID, etc.)
DROP TABLE IF EXISTS public.skills CASCADE;
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- 2. Drop and recreate GOALS (had goalID, personID, projectID, etc.)
DROP TABLE IF EXISTS public.goals CASCADE;
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text,
    project_id integer
);

-- 3. Drop and recreate SCORES (had scoreID, personID, healthGlobalScore, etc.)
DROP TABLE IF EXISTS public.scores CASCADE;
CREATE TABLE IF NOT EXISTS scores (
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

-- 4. Drop and recreate PROJECTS (had projectID, personID, createdAt, etc.)
DROP TABLE IF EXISTS public.projects CASCADE;
CREATE TABLE IF NOT EXISTS projects (
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

-- 5. Drop and recreate PERSON_WIDGETS (had personWidgetID, personID, etc.)
DROP TABLE IF EXISTS public.person_widgets CASCADE;
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- 6. Drop and recreate THEMES (had addedDate issue)
DROP TABLE IF EXISTS public.themes CASCADE;
CREATE TABLE IF NOT EXISTS themes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    theme_id SERIAL UNIQUE,
    name text,
    alias text,
    json_content text,
    author text,
    added_date text
);

-- 7. Drop and recreate INTERNAL_WIDGETS (missing date_added in Supabase)
DROP TABLE IF EXISTS public.internal_widgets CASCADE;
CREATE TABLE IF NOT EXISTS internal_widgets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    widget_id integer,
    name text,
    url text,
    date_added text,
    image_url text,
    alias text
);

-- 8. Drop and recreate EXTERNAL_WIDGETS
DROP TABLE IF EXISTS public.external_widgets CASCADE;
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

-- 9. Drop and recreate BLOG_POSTS (missing author_id in Supabase)
DROP TABLE IF EXISTS public.blog_posts CASCADE;
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
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- 10. Ensure PERSONS table uses snake_case (fix created_at if it was createdAt)
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
END $$;

-- 11. Re-enable RLS and policies for ALL recreated tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_type = 'BASE TABLE'
          AND table_name IN (
            'skills', 'goals', 'scores', 'projects', 'person_widgets', 
            'themes', 'internal_widgets', 'external_widgets', 'blog_posts'
          )
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS "Permissive Policy" ON public.%I', t);
        EXECUTE format('CREATE POLICY "Permissive Policy" ON public.%I FOR ALL USING (true) WITH CHECK (true)', t);
    END LOOP;
END $$;

-- 12. Refresh PowerSync publication
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR ALL TABLES;
