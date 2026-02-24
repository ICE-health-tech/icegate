-- SUPABASE RECREATE SCHEMA SCRIPT
-- WARNING: This will DELETE ALL DATA in the public schema and recreate all tables.
-- 0. Cleanup - Drop all tables if they exist
DROP TABLE IF EXISTS quests CASCADE;

DROP TABLE IF EXISTS exercise_logs CASCADE;

DROP TABLE IF EXISTS sleep_logs CASCADE;

DROP TABLE IF EXISTS water_logs CASCADE;

DROP TABLE IF EXISTS quotes CASCADE;

DROP TABLE IF EXISTS custom_notifications CASCADE;

DROP TABLE IF EXISTS focus_sessions CASCADE;

DROP TABLE IF EXISTS transactions CASCADE;

DROP TABLE IF EXISTS projects CASCADE;

DROP TABLE IF EXISTS themes_config CASCADE;

DROP TABLE IF EXISTS days CASCADE;

DROP TABLE IF EXISTS meals CASCADE;

DROP TABLE IF EXISTS health_metrics CASCADE;

DROP TABLE IF EXISTS person_widgets CASCADE;

DROP TABLE IF EXISTS blog_posts CASCADE;

DROP TABLE IF EXISTS habits CASCADE;

DROP TABLE IF EXISTS goals CASCADE;

DROP TABLE IF EXISTS assets CASCADE;

DROP TABLE IF EXISTS financial_accounts CASCADE;

DROP TABLE IF EXISTS skills CASCADE;

DROP TABLE IF EXISTS detail_information CASCADE;

DROP TABLE IF EXISTS profiles CASCADE;

DROP TABLE IF EXISTS user_accounts CASCADE;

DROP TABLE IF EXISTS email_addresses CASCADE;

DROP TABLE IF EXISTS persons CASCADE;

DROP TABLE IF EXISTS project_notes CASCADE;

DROP TABLE IF EXISTS internal_widgets CASCADE;

DROP TABLE IF EXISTS external_widgets CASCADE;

DROP TABLE IF EXISTS themes CASCADE;

DROP TABLE IF EXISTS organizations CASCADE;

DROP TABLE IF EXISTS sessions CASCADE;

DROP TABLE IF EXISTS scores CASCADE;

-- 1. Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    domain TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 2. Persons (Core Identity)
CREATE TABLE persons (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    person_id TEXT, -- PowerSync ID
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

-- 3. Email Addresses
CREATE TABLE email_addresses (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    email_address_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    email_address TEXT NOT NULL,
    email_type TEXT DEFAULT 'personal',
    is_primary BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'pending',
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 4. User Accounts
CREATE TABLE user_accounts (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    account_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    primary_email_id UUID REFERENCES email_addresses (id),
    role TEXT DEFAULT 'user',
    is_locked BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    last_login_at TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ DEFAULT NOW (),
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 5. Profiles
CREATE TABLE profiles (
    id UUID PRIMARY KEY,
    profile_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE UNIQUE,
    bio TEXT,
    occupation TEXT,
    education_level TEXT,
    location TEXT,
    website_url TEXT,
    linkedin_url TEXT,
    github_url TEXT,
    timezone TEXT,
    preferred_language TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 6. Detail Information (CV Address)
CREATE TABLE detail_information (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    cv_address_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE UNIQUE,
    github_url TEXT,
    website_url TEXT,
    company TEXT,
    university TEXT,
    location TEXT,
    country TEXT,
    bio TEXT,
    occupation TEXT,
    education_level TEXT,
    linkedin_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 7. Projects
CREATE TABLE projects (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    project_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    color TEXT,
    status INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 8. Project Notes
CREATE TABLE project_notes (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    note_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    project_id UUID REFERENCES projects (id) ON DELETE CASCADE
);

-- 9. Goals
CREATE TABLE goals (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    goal_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'personal',
    priority INTEGER DEFAULT 3,
    status TEXT DEFAULT 'active',
    target_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    progress_percentage INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    project_id UUID REFERENCES projects (id) ON DELETE CASCADE
);

-- 10. Habits
CREATE TABLE habits (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    habit_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    goal_id UUID REFERENCES goals (id) ON DELETE SET NULL,
    habit_name TEXT NOT NULL,
    description TEXT,
    frequency TEXT NOT NULL,
    frequency_details TEXT,
    target_count INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    started_date TIMESTAMPTZ DEFAULT NOW (),
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 11. Skills
CREATE TABLE skills (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    skill_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    skill_category TEXT,
    proficiency_level TEXT DEFAULT 'beginner',
    years_of_experience INTEGER DEFAULT 0,
    description TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 12. Financial Accounts
CREATE TABLE financial_accounts (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    account_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    account_name TEXT NOT NULL,
    account_type TEXT DEFAULT 'checking',
    balance REAL DEFAULT 0.0,
    currency TEXT DEFAULT 'USD',
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 13. Assets
CREATE TABLE assets (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    asset_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    asset_name TEXT NOT NULL,
    asset_category TEXT NOT NULL,
    purchase_date TIMESTAMPTZ,
    purchase_price REAL,
    current_estimated_value REAL,
    currency TEXT DEFAULT 'USD',
    condition TEXT DEFAULT 'good',
    location TEXT,
    notes TEXT,
    is_insured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 14. Transactions
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    transaction_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    description TEXT,
    transaction_date TIMESTAMPTZ DEFAULT NOW (),
    created_at TIMESTAMPTZ DEFAULT NOW (),
    project_id UUID REFERENCES projects (id) ON DELETE CASCADE
);

-- 15. Blog Posts
CREATE TABLE blog_posts (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    post_id TEXT,
    author_id UUID REFERENCES persons (id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
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

-- 16. Person Widgets
CREATE TABLE person_widgets (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    person_widget_id INTEGER,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    widget_name TEXT NOT NULL,
    widget_type TEXT NOT NULL,
    configuration TEXT DEFAULT '{}',
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    role TEXT DEFAULT 'admin',
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 17. Health Metrics
CREATE TABLE health_metrics (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    metric_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    date DATE NOT NULL,
    steps INTEGER DEFAULT 0,
    heart_rate INTEGER DEFAULT 0,
    sleep_hours REAL DEFAULT 0.0,
    water_glasses INTEGER DEFAULT 0,
    exercise_minutes INTEGER DEFAULT 0,
    focus_minutes INTEGER DEFAULT 0,
    weight_kg REAL DEFAULT 0.0,
    calories_consumed INTEGER DEFAULT 0,
    calories_burned INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    UNIQUE (person_id, date)
);

-- 18. Meals
CREATE TABLE meals (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    meal_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    meal_name TEXT NOT NULL,
    meal_image_url TEXT,
    fat REAL DEFAULT 0.0,
    carbs REAL DEFAULT 0.0,
    protein REAL DEFAULT 0.0,
    calories REAL DEFAULT 0.0,
    eaten_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 19. Days (Summary)
CREATE TABLE days (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    day_id DATE NOT NULL,
    weight INTEGER DEFAULT 0,
    calories_out INTEGER DEFAULT 0
);

-- 20. Scores
CREATE TABLE scores (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    score_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE UNIQUE,
    health_global_score REAL DEFAULT 0.0,
    social_global_score REAL DEFAULT 0.0,
    financial_global_score REAL DEFAULT 0.0,
    career_global_score REAL DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW (),
    updated_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 21. Internal Widgets
CREATE TABLE internal_widgets (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    widget_id TEXT,
    name TEXT,
    url TEXT,
    date_added TEXT,
    image_url TEXT,
    alias TEXT
);

-- 22. External Widgets
CREATE TABLE external_widgets (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    widget_id TEXT,
    name TEXT,
    alias TEXT,
    protocol TEXT,
    host TEXT,
    url TEXT,
    image_url TEXT,
    date_added TEXT
);

-- 23. Themes
CREATE TABLE themes (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    theme_id TEXT,
    name TEXT NOT NULL,
    alias TEXT UNIQUE NOT NULL,
    json_content TEXT NOT NULL,
    author TEXT NOT NULL,
    added_date TIMESTAMPTZ NOT NULL
);

-- 24. Themes Config
CREATE TABLE themes_config (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    theme_id TEXT,
    theme_name TEXT NOT NULL,
    theme_path TEXT NOT NULL
);

-- 25. Focus Sessions
CREATE TABLE focus_sessions (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    session_id INTEGER,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects (id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_seconds INTEGER NOT NULL,
    status TEXT NOT NULL,
    task_id UUID REFERENCES goals (id) ON DELETE CASCADE,
    notes TEXT
);

-- 26. Custom Notifications
CREATE TABLE custom_notifications (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    notification_id TEXT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    scheduled_time TIMESTAMPTZ NOT NULL,
    repeat_frequency TEXT DEFAULT 'none',
    repeat_days TEXT,
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 27. Quotes
CREATE TABLE quotes (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    quote_id INTEGER,
    content TEXT NOT NULL,
    author TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 28. Quests
CREATE TABLE quests (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    quest_id TEXT,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT DEFAULT 'daily',
    target_value REAL DEFAULT 0.0,
    current_value REAL DEFAULT 0.0,
    category TEXT DEFAULT 'health',
    reward_exp INTEGER DEFAULT 10,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW ()
);

-- 29. Water Logs
CREATE TABLE water_logs (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    log_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    amount INTEGER DEFAULT 0,
    timestamp TIMESTAMPTZ DEFAULT NOW ()
);

-- 30. Sleep Logs
CREATE TABLE sleep_logs (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    log_id TEXT,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    quality INTEGER DEFAULT 3
);

-- 31. Exercise Logs
CREATE TABLE exercise_logs (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    log_id INTEGER,
    person_id UUID REFERENCES persons (id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    intensity TEXT DEFAULT 'medium',
    timestamp TIMESTAMPTZ DEFAULT NOW ()
);

-- 32. Sessions (App Sessions)
CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES organizations (id) ON DELETE CASCADE,
    local_id TEXT,
    jwt TEXT NOT NULL,
    username TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW ()
);