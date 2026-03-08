-- Migration: Add 'category' column to metrics tables and update unique constraints
-- Date: 2026-03-08
-- 1. Add category column to metrics tables
ALTER TABLE public.health_metrics
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General';

ALTER TABLE public.financial_metrics
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General';

ALTER TABLE public.project_metrics
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General';

ALTER TABLE public.social_metrics
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'General';

-- 2. Update unique constraints
-- Note: We drop existing constraints if they exist and create new ones including 'category'
-- Financial Metrics
ALTER TABLE public.financial_metrics
DROP CONSTRAINT IF EXISTS financial_metrics_person_date_key,
DROP CONSTRAINT IF EXISTS financial_metrics_person_id_date_key;

ALTER TABLE public.financial_metrics ADD CONSTRAINT financial_metrics_person_date_category_key UNIQUE (person_id, date, category);

-- Project Metrics
ALTER TABLE public.project_metrics
DROP CONSTRAINT IF EXISTS project_metrics_person_date_key,
DROP CONSTRAINT IF EXISTS project_metrics_person_id_date_key;

ALTER TABLE public.project_metrics ADD CONSTRAINT project_metrics_person_date_category_key UNIQUE (person_id, date, category);

-- Social Metrics
ALTER TABLE public.social_metrics
DROP CONSTRAINT IF EXISTS social_metrics_person_date_key,
DROP CONSTRAINT IF EXISTS social_metrics_person_id_date_key;

ALTER TABLE public.social_metrics ADD CONSTRAINT social_metrics_person_date_category_key UNIQUE (person_id, date, category);

-- Health Metrics (Assuming standard naming if any existed, or adding new one)
-- Health metrics usually has health_metrics_person_id_date_key in some setups
ALTER TABLE public.health_metrics
DROP CONSTRAINT IF EXISTS health_metrics_person_id_date_key;

ALTER TABLE public.health_metrics ADD CONSTRAINT health_metrics_person_id_date_category_key UNIQUE (person_id, date, category);

-- 3. Update indices for performance
DROP INDEX IF EXISTS idx_health_metrics_person_date;

CREATE INDEX IF NOT EXISTS idx_health_metrics_person_date_category ON public.health_metrics (person_id, date, category);

DROP INDEX IF EXISTS idx_financial_metrics_person_date;

CREATE INDEX IF NOT EXISTS idx_financial_metrics_person_date_category ON public.financial_metrics (person_id, date, category);

DROP INDEX IF EXISTS idx_project_metrics_person_date;

CREATE INDEX IF NOT EXISTS idx_project_metrics_person_date_category ON public.project_metrics (person_id, date, category);

DROP INDEX IF EXISTS idx_social_metrics_person_date;

CREATE INDEX IF NOT EXISTS idx_social_metrics_person_date_category ON public.social_metrics (person_id, date, category);