-- PostgreSQL/Supabase Setup Script
-- Generated from SQLite template for PowerSync compatibility
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABLES
CREATE TABLE IF NOT EXISTS public.internal_widgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    internal_widget_id SERIAL, -- For legacy reference if needed
    name TEXT,
    url TEXT,
    date_added TIMESTAMPTZ DEFAULT NOW (),
    image_url TEXT,
    alias TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS public.external_widgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    widget_id SERIAL,
    name TEXT NOT NULL,
    alias TEXT UNIQUE,
    protocol TEXT NOT NULL,
    host TEXT NOT NULL,
    url TEXT NOT NULL,
    image_url TEXT,
    date_added TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.themes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    name TEXT NOT NULL,
    alias TEXT NOT NULL UNIQUE,
    json_content TEXT NOT NULL,
    author TEXT NOT NULL,
    added_date TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.persons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id SERIAL,
    first_name TEXT NOT NULL,
    last_name TEXT,
    date_of_birth DATE,
    gender TEXT,
    phone_number TEXT,
    profile_image_url TEXT,
    relationship TEXT DEFAULT 'none',
    affection INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.email_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    email_address TEXT NOT NULL,
    email_type TEXT DEFAULT 'personal',
    is_primary BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'pending',
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.user_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    primary_email_id UUID REFERENCES public.email_addresses (id),
    role TEXT DEFAULT 'user',
    is_locked BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    last_login_at TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ DEFAULT NOW (),
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID UNIQUE REFERENCES public.persons (id) ON DELETE CASCADE,
    bio TEXT,
    occupation TEXT,
    education_level TEXT,
    location TEXT,
    website_url TEXT,
    linkedin_url TEXT,
    github_url TEXT,
    timezone TEXT DEFAULT 'UTC',
    preferred_language TEXT DEFAULT 'en',
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    name TEXT -- For display name caching
);

CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    color TEXT,
    status INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.project_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    project_id UUID REFERENCES public.projects (id) ON DELETE CASCADE,
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    skill_category TEXT,
    proficiency_level TEXT DEFAULT 'beginner',
    years_of_experience INTEGER DEFAULT 0,
    description TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.financial_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    account_name TEXT NOT NULL,
    account_type TEXT DEFAULT 'checking',
    balance DECIMAL(15, 2) DEFAULT 0.00,
    currency TEXT DEFAULT 'USD',
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    asset_name TEXT NOT NULL,
    asset_category TEXT NOT NULL,
    purchase_date DATE,
    purchase_price DECIMAL(15, 2),
    current_estimated_value DECIMAL(15, 2),
    currency TEXT DEFAULT 'USD',
    condition TEXT DEFAULT 'good',
    location TEXT,
    notes TEXT,
    is_insured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects (id) ON DELETE SET NULL,
    category TEXT NOT NULL,
    type TEXT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT,
    transaction_date TIMESTAMPTZ DEFAULT NOW (),
    created_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects (id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'personal',
    priority INTEGER DEFAULT 3,
    status TEXT DEFAULT 'active',
    target_date DATE,
    completion_date DATE,
    progress_percentage INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID UNIQUE REFERENCES public.persons (id) ON DELETE CASCADE,
    health_global_score REAL DEFAULT 0.0,
    social_global_score REAL DEFAULT 0.0,
    financial_global_score REAL DEFAULT 0.0,
    career_global_score REAL DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    goal_id UUID REFERENCES public.goals (id) ON DELETE SET NULL,
    habit_name TEXT NOT NULL,
    description TEXT,
    frequency TEXT NOT NULL,
    frequency_details TEXT,
    target_count INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    started_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.blog_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    author_id UUID REFERENCES public.persons (id),
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    excerpt TEXT,
    content TEXT NOT NULL,
    featured_image_url TEXT,
    status TEXT DEFAULT 'draft',
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    published_at TIMESTAMPTZ,
    scheduled_for TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.health_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    date DATE NOT NULL,
    steps INTEGER DEFAULT 0,
    heart_rate INTEGER DEFAULT 0,
    sleep_hours REAL DEFAULT 0.0,
    water_glasses INTEGER DEFAULT 0,
    exercise_minutes INTEGER DEFAULT 0,
    weight_kg REAL DEFAULT 0.0,
    calories_consumed INTEGER DEFAULT 0,
    calories_burned INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    UNIQUE (person_id, date)
);

CREATE TABLE IF NOT EXISTS public.meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    meal_name TEXT NOT NULL,
    meal_image_url TEXT,
    fat REAL DEFAULT 0.0,
    carbs REAL DEFAULT 0.0,
    protein REAL DEFAULT 0.0,
    calories REAL DEFAULT 0.0,
    eaten_at TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.water_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    timestamp TIMESTAMPTZ DEFAULT NOW ()
);

CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    quality INTEGER DEFAULT 3
);

CREATE TABLE IF NOT EXISTS public.exercise_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    intensity TEXT DEFAULT 'medium',
    timestamp TIMESTAMPTZ DEFAULT NOW ()
);

-- Row Level Security (RLS) Enablement
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.email_addresses ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_accounts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.project_notes ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.financial_accounts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.exercise_logs ENABLE ROW LEVEL SECURITY;

-- 2. SEED DATA (Placeholder UUIDs used for relationships)
-- Note: In production, IDs often link to auth.users.id
WITH
    new_person AS (
        INSERT INTO
            public.persons (
                first_name,
                last_name,
                date_of_birth,
                gender,
                phone_number,
                profile_image_url
            )
        VALUES
            (
                'Long',
                'Duy',
                '1995-01-01',
                'Male',
                '+84 123 456 789',
                'https://example.com/avatar.jpg'
            ) RETURNING id
    ),
    new_email AS (
        INSERT INTO
            public.email_addresses (
                person_id,
                email_address,
                email_type,
                is_primary,
                status
            )
        SELECT
            id,
            'long@example.com',
            'personal',
            TRUE,
            'verified'
        FROM
            new_person RETURNING id
    )
INSERT INTO
    public.profiles (
        person_id,
        bio,
        occupation,
        education_level,
        location,
        website_url,
        name
    )
SELECT
    id,
    'Flutter Developer & Tech Enthusiast',
    'Software Engineer',
    'Bachelor',
    'Ho Chi Minh City, Vietnam',
    'https://duylong.dev',
    'Long Duy'
FROM
    new_person;

-- financial accounts for the person
INSERT INTO
    public.financial_accounts (
        person_id,
        account_name,
        account_type,
        balance,
        currency,
        is_primary
    )
SELECT
    id,
    'Main Checking',
    'checking',
    1500.00,
    'USD',
    TRUE
FROM
    public.persons
WHERE
    first_name = 'Long';

INSERT INTO
    public.financial_accounts (
        person_id,
        account_name,
        account_type,
        balance,
        currency
    )
SELECT
    id,
    'Savings',
    'savings',
    5000.00,
    'USD'
FROM
    public.persons
WHERE
    first_name = 'Long';

-- assets
INSERT INTO
    public.assets (
        person_id,
        asset_name,
        asset_category,
        current_estimated_value,
        currency
    )
SELECT
    id,
    'MacBook Pro',
    'electronics',
    2000.00,
    'USD'
FROM
    public.persons
WHERE
    first_name = 'Long';

-- skills
INSERT INTO
    public.skills (
        person_id,
        skill_name,
        proficiency_level,
        years_of_experience,
        is_featured
    )
SELECT
    id,
    'Flutter',
    'expert',
    4,
    TRUE
FROM
    public.persons
WHERE
    first_name = 'Long';

-- blog posts
INSERT INTO
    public.blog_posts (
        author_id,
        title,
        slug,
        content,
        status,
        published_at
    )
SELECT
    id,
    'Hello World',
    'hello-world',
    'This is my first post on the new platform.',
    'published',
    NOW ()
FROM
    public.persons
WHERE
    first_name = 'Long';