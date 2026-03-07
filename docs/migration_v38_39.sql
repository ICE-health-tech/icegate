-- Migration v38 -> v39
-- Create health_metrics table
-- Explicitly following user-provided schema + quest_points
CREATE TABLE IF NOT EXISTS public.health_metrics (
    id uuid NOT NULL,
    tenant_id uuid NULL,
    metric_id text NULL,
    person_id uuid NULL,
    date date NOT NULL,
    steps INTEGER NULL DEFAULT 0,
    heart_rate INTEGER NULL DEFAULT 0,
    sleep_hours REAL NULL DEFAULT 0.0,
    water_glasses INTEGER NULL DEFAULT 0,
    exercise_minutes INTEGER NULL DEFAULT 0,
    focus_minutes INTEGER NULL DEFAULT 0,
    weight_kg REAL NULL DEFAULT 0.0,
    calories_consumed INTEGER NULL DEFAULT 0,
    calories_burned INTEGER NULL DEFAULT 0,
    quest_points DOUBLE PRECISION NULL DEFAULT 0.0,
    updated_at timestamp
    with
        time zone NULL DEFAULT now (),
        CONSTRAINT health_metrics_pkey PRIMARY KEY (id),
        CONSTRAINT health_metrics_person_id_date_key UNIQUE (person_id, date),
        CONSTRAINT health_metrics_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons (id) ON DELETE CASCADE,
        CONSTRAINT health_metrics_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.organizations (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Create financial_metrics table
CREATE TABLE IF NOT EXISTS public.financial_metrics (
    id uuid NOT NULL DEFAULT gen_random_uuid (),
    tenant_id uuid NULL,
    metric_id text NULL,
    person_id uuid NULL,
    date date NOT NULL,
    total_balance DOUBLE PRECISION NULL DEFAULT 0.0,
    total_savings DOUBLE PRECISION NULL DEFAULT 0.0,
    total_investments DOUBLE PRECISION NULL DEFAULT 0.0,
    daily_expenses DOUBLE PRECISION NULL DEFAULT 0.0,
    quest_points DOUBLE PRECISION NULL DEFAULT 0.0,
    updated_at timestamp
    with
        time zone NULL DEFAULT now (),
        CONSTRAINT financial_metrics_pkey PRIMARY KEY (id),
        CONSTRAINT financial_metrics_person_id_date_key UNIQUE (person_id, date),
        CONSTRAINT financial_metrics_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons (id) ON DELETE CASCADE,
        CONSTRAINT financial_metrics_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.organizations (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Create project_metrics table
CREATE TABLE IF NOT EXISTS public.project_metrics (
    id uuid NOT NULL DEFAULT gen_random_uuid (),
    tenant_id uuid NULL,
    metric_id text NULL,
    person_id uuid NULL,
    date date NOT NULL,
    tasks_completed INTEGER NULL DEFAULT 0,
    projects_completed INTEGER NULL DEFAULT 0,
    focus_minutes INTEGER NULL DEFAULT 0,
    quest_points DOUBLE PRECISION NULL DEFAULT 0.0,
    updated_at timestamp
    with
        time zone NULL DEFAULT now (),
        CONSTRAINT project_metrics_pkey PRIMARY KEY (id),
        CONSTRAINT project_metrics_person_id_date_key UNIQUE (person_id, date),
        CONSTRAINT project_metrics_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons (id) ON DELETE CASCADE,
        CONSTRAINT project_metrics_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.organizations (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Create social_metrics table
CREATE TABLE IF NOT EXISTS public.social_metrics (
    id uuid NOT NULL DEFAULT gen_random_uuid (),
    tenant_id uuid NULL,
    metric_id text NULL,
    person_id uuid NULL,
    date date NOT NULL,
    contacts_count INTEGER NULL DEFAULT 0,
    total_affection INTEGER NULL DEFAULT 0,
    quest_points DOUBLE PRECISION NULL DEFAULT 0.0,
    updated_at timestamp
    with
        time zone NULL DEFAULT now (),
        CONSTRAINT social_metrics_pkey PRIMARY KEY (id),
        CONSTRAINT social_metrics_person_id_date_key UNIQUE (person_id, date),
        CONSTRAINT social_metrics_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons (id) ON DELETE CASCADE,
        CONSTRAINT social_metrics_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.organizations (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Enable RLS
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.financial_metrics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.project_metrics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.social_metrics ENABLE ROW LEVEL SECURITY;