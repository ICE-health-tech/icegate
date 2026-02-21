-- PostgreSQL Database Schema
-- Converted from Drift Database Schema (Database.dart)
-- For testing purposes

-- Drop existing tables if they exist (in reverse order due to foreign keys)
DROP TABLE IF EXISTS person_widgets CASCADE;
DROP TABLE IF EXISTS blog_posts CASCADE;
DROP TABLE IF EXISTS habits CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS assets CASCADE;
DROP TABLE IF EXISTS financial_accounts CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS cv_addresses CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS user_accounts CASCADE;
DROP TABLE IF EXISTS email_addresses CASCADE;
DROP TABLE IF EXISTS persons CASCADE;
DROP TABLE IF EXISTS project_notes CASCADE;
DROP TABLE IF EXISTS internal_widgets CASCADE;
DROP TABLE IF EXISTS themes CASCADE;
DROP TABLE IF EXISTS external_widgets CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS post_status CASCADE;
DROP TYPE IF EXISTS email_status CASCADE;
DROP TYPE IF EXISTS currency_type CASCADE;
DROP TYPE IF EXISTS skill_level CASCADE;

-- Create custom types (enums)
CREATE TYPE user_role AS ENUM ('user', 'admin', 'viewer');
CREATE TYPE post_status AS ENUM ('draft', 'published', 'archived', 'deleted');
CREATE TYPE email_status AS ENUM ('pending', 'verified', 'bounced', 'disabled');
CREATE TYPE currency_type AS ENUM ('USD', 'EUR', 'VND', 'JPY', 'GBP', 'CNY');
CREATE TYPE skill_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');

-- ============================================================================
-- WIDGET TABLES
-- ============================================================================

-- Internal Widgets Table
CREATE TABLE internal_widgets (
    internal_widget_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    url VARCHAR(100),
    date_added TEXT NOT NULL,
    image_url TEXT NOT NULL,
    alias TEXT NOT NULL
);

-- External Widgets Table
CREATE TABLE external_widgets (
    widget_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    alias VARCHAR(100),
    protocol TEXT NOT NULL,
    host TEXT NOT NULL,
    url TEXT NOT NULL,
    image_url TEXT,
    date_added TEXT NOT NULL
);

-- Themes Table
CREATE TABLE themes (
    theme_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    alias VARCHAR(50) NOT NULL UNIQUE,
    json_content TEXT NOT NULL,
    author VARCHAR(50) NOT NULL,
    added_date TIMESTAMP NOT NULL
);

-- Project Notes Table
CREATE TABLE project_notes (
    note_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PERSON MANAGEMENT TABLES
-- ============================================================================

-- Persons Table
CREATE TABLE persons (
    person_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name TEXT,
    date_of_birth TIMESTAMP,
    gender TEXT,
    phone_number VARCHAR(20),
    profile_image_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Email Addresses Table
CREATE TABLE email_addresses (
    email_address_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    email_address VARCHAR(320) NOT NULL,
    email_type TEXT NOT NULL DEFAULT 'personal',
    is_primary BOOLEAN NOT NULL DEFAULT false,
    status email_status NOT NULL DEFAULT 'pending',
    verified_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- User Accounts Table
CREATE TABLE user_accounts (
    account_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    primary_email_id INTEGER REFERENCES email_addresses(email_address_id),
    role user_role NOT NULL DEFAULT 'user',
    is_locked BOOLEAN NOT NULL DEFAULT false,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    last_login_at TIMESTAMP,
    password_changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Profiles Table
CREATE TABLE profiles (
    profile_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL UNIQUE REFERENCES persons(person_id) ON DELETE CASCADE,
    bio TEXT,
    occupation TEXT,
    education_level TEXT,
    location TEXT,
    website_url TEXT,
    linkedin_url TEXT,
    github_url TEXT,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    preferred_language TEXT NOT NULL DEFAULT 'en',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CV Addresses Table
CREATE TABLE cv_addresses (
    cv_address_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL UNIQUE REFERENCES persons(person_id) ON DELETE CASCADE,
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
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Skills Table
CREATE TABLE skills (
    skill_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    skill_category TEXT,
    proficiency_level skill_level NOT NULL DEFAULT 'beginner',
    years_of_experience INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FINANCE TABLES
-- ============================================================================

-- Financial Accounts Table
CREATE TABLE financial_accounts (
    account_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL DEFAULT 'checking',
    balance REAL NOT NULL DEFAULT 0.0,
    currency currency_type NOT NULL DEFAULT 'USD',
    is_primary BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Assets Table
CREATE TABLE assets (
    asset_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    asset_name TEXT NOT NULL,
    asset_category TEXT NOT NULL,
    purchase_date TIMESTAMP,
    purchase_price REAL,
    current_estimated_value REAL,
    currency currency_type NOT NULL DEFAULT 'USD',
    condition TEXT NOT NULL DEFAULT 'good',
    location TEXT,
    notes TEXT,
    is_insured BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- GROWTH/GOALS TABLES
-- ============================================================================

-- Goals Table
CREATE TABLE goals (
    goal_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'personal',
    priority INTEGER NOT NULL DEFAULT 3,
    status TEXT NOT NULL DEFAULT 'active',
    target_date TIMESTAMP,
    completion_date TIMESTAMP,
    progress_percentage INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Habits Table
CREATE TABLE habits (
    habit_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    goal_id INTEGER REFERENCES goals(goal_id) ON DELETE SET NULL,
    habit_name TEXT NOT NULL,
    description TEXT,
    frequency TEXT NOT NULL,
    frequency_details TEXT,
    target_count INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    started_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CONTENT TABLES
-- ============================================================================

-- Blog Posts Table
CREATE TABLE blog_posts (
    post_id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    excerpt TEXT,
    content TEXT NOT NULL,
    featured_image_url TEXT,
    status post_status NOT NULL DEFAULT 'draft',
    is_featured BOOLEAN NOT NULL DEFAULT false,
    view_count INTEGER NOT NULL DEFAULT 0,
    like_count INTEGER NOT NULL DEFAULT 0,
    published_at TIMESTAMP,
    scheduled_for TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Person Widgets Table
CREATE TABLE person_widgets (
    person_widget_id SERIAL PRIMARY KEY,
    person_id INTEGER NOT NULL REFERENCES persons(person_id) ON DELETE CASCADE,
    widget_name TEXT NOT NULL,
    widget_type TEXT NOT NULL,
    configuration TEXT NOT NULL DEFAULT '{}',
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    role user_role NOT NULL DEFAULT 'admin',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Person-related indexes
CREATE INDEX idx_email_addresses_person_id ON email_addresses(person_id);
CREATE INDEX idx_email_addresses_email ON email_addresses(email_address);
CREATE INDEX idx_user_accounts_person_id ON user_accounts(person_id);
CREATE INDEX idx_user_accounts_username ON user_accounts(username);
CREATE INDEX idx_profiles_person_id ON profiles(person_id);
CREATE INDEX idx_cv_addresses_person_id ON cv_addresses(person_id);

-- Skills indexes
CREATE INDEX idx_skills_person_id ON skills(person_id);
CREATE INDEX idx_skills_category ON skills(skill_category);

-- Finance indexes
CREATE INDEX idx_financial_accounts_person_id ON financial_accounts(person_id);
CREATE INDEX idx_assets_person_id ON assets(person_id);
CREATE INDEX idx_assets_category ON assets(asset_category);

-- Goals/Habits indexes
CREATE INDEX idx_goals_person_id ON goals(person_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_habits_person_id ON habits(person_id);
CREATE INDEX idx_habits_goal_id ON habits(goal_id);

-- Content indexes
CREATE INDEX idx_blog_posts_author_id ON blog_posts(author_id);
CREATE INDEX idx_blog_posts_slug ON blog_posts(slug);
CREATE INDEX idx_blog_posts_status ON blog_posts(status);

-- Widget indexes
CREATE INDEX idx_person_widgets_person_id ON person_widgets(person_id);

-- Project notes indexes
CREATE INDEX idx_project_notes_updated_at ON project_notes(updated_at DESC);

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Insert sample person
INSERT INTO persons (person_id, first_name, last_name, date_of_birth, gender, phone_number, is_active)
VALUES (1, 'John', 'Doe', '1990-01-15', 'male', '+1234567890', true);

-- Insert sample email
INSERT INTO email_addresses (email_address_id, person_id, email_address, email_type, is_primary, status)
VALUES (1, 1, 'john.doe@example.com', 'personal', true, 'verified');

-- Insert sample user account
INSERT INTO user_accounts (account_id, person_id, username, password_hash, primary_email_id, role)
VALUES (1, 1, 'johndoe', 'hashed_password_here', 1, 'user');

-- Insert sample profile
INSERT INTO profiles (profile_id, person_id, bio, occupation, location)
VALUES (1, 1, 'Software developer passionate about Flutter and mobile apps', 'Software Engineer', 'San Francisco, CA');

-- Insert sample CV address
INSERT INTO cv_addresses (cv_address_id, person_id, github_url, linkedin_url, location, country)
VALUES (1, 1, 'https://github.com/johndoe', 'https://linkedin.com/in/johndoe', 'San Francisco', 'USA');

-- Insert sample skill
INSERT INTO skills (person_id, skill_name, skill_category, proficiency_level, years_of_experience)
VALUES (1, 'Flutter', 'Mobile Development', 'advanced', 3);

-- Insert sample financial account
INSERT INTO financial_accounts (person_id, account_name, account_type, balance, currency, is_primary)
VALUES (1, 'Main Checking', 'checking', 5000.00, 'USD', true);

-- Insert sample goal
INSERT INTO goals (person_id, title, description, category, priority, status)
VALUES (1, 'Learn PostgreSQL', 'Master PostgreSQL for backend development', 'professional', 2, 'active');

-- Insert sample project note
INSERT INTO project_notes (title, content, created_at, updated_at)
VALUES ('Database Migration', '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Converting Drift schema to PostgreSQL"}]}]}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS (Optional - for auto-updating timestamps)
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for all tables with updated_at
CREATE TRIGGER update_persons_updated_at BEFORE UPDATE ON persons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cv_addresses_updated_at BEFORE UPDATE ON cv_addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_accounts_updated_at BEFORE UPDATE ON user_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skills_updated_at BEFORE UPDATE ON skills FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_financial_accounts_updated_at BEFORE UPDATE ON financial_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_habits_updated_at BEFORE UPDATE ON habits FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_blog_posts_updated_at BEFORE UPDATE ON blog_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_person_widgets_updated_at BEFORE UPDATE ON person_widgets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_project_notes_updated_at BEFORE UPDATE ON project_notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- View all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- View all custom types
SELECT typname 
FROM pg_type 
WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND typtype = 'e'
ORDER BY typname;

-- Count records in each table
SELECT 
    'persons' as table_name, COUNT(*) as record_count FROM persons
UNION ALL SELECT 'email_addresses', COUNT(*) FROM email_addresses
UNION ALL SELECT 'user_accounts', COUNT(*) FROM user_accounts
UNION ALL SELECT 'profiles', COUNT(*) FROM profiles
UNION ALL SELECT 'cv_addresses', COUNT(*) FROM cv_addresses
UNION ALL SELECT 'skills', COUNT(*) FROM skills
UNION ALL SELECT 'financial_accounts', COUNT(*) FROM financial_accounts
UNION ALL SELECT 'assets', COUNT(*) FROM assets
UNION ALL SELECT 'goals', COUNT(*) FROM goals
UNION ALL SELECT 'habits', COUNT(*) FROM habits
UNION ALL SELECT 'blog_posts', COUNT(*) FROM blog_posts
UNION ALL SELECT 'person_widgets', COUNT(*) FROM person_widgets
UNION ALL SELECT 'project_notes', COUNT(*) FROM project_notes
UNION ALL SELECT 'internal_widgets', COUNT(*) FROM internal_widgets
UNION ALL SELECT 'external_widgets', COUNT(*) FROM external_widgets
UNION ALL SELECT 'themes', COUNT(*) FROM themes;
