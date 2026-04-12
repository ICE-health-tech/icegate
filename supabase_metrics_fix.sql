-- SQL to fix PostgrestException 42P10
-- Run this in your Supabase SQL Editor

-- 1. Health Metrics
-- Remove old narrower constraint if it exists
ALTER TABLE health_metrics DROP CONSTRAINT IF EXISTS health_metrics_person_id_date_key; -- Name might vary, check your Supabase UI

-- Create the correct composite unique index that matches PowerSync's ON CONFLICT specification
CREATE UNIQUE INDEX IF NOT EXISTS health_metrics_uniqueness_idx 
ON health_metrics (person_id, date, category);

-- 2. Financial Metrics
CREATE UNIQUE INDEX IF NOT EXISTS financial_metrics_uniqueness_idx 
ON financial_metrics (person_id, date, category);

-- 3. Project Metrics
CREATE UNIQUE INDEX IF NOT EXISTS project_metrics_uniqueness_idx 
ON project_metrics (person_id, date, category);

-- 4. Social Metrics
CREATE UNIQUE INDEX IF NOT EXISTS social_metrics_uniqueness_idx 
ON social_metrics (person_id, date, category);

-- Optional: Verify constraints
-- SELECT 
--     conname as constraint_name, 
--     contype as constraint_type 
-- FROM pg_catalog.pg_constraint con
-- INNER JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
-- WHERE rel.relname IN ('health_metrics', 'financial_metrics', 'project_metrics', 'social_metrics');
