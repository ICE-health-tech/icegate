-- Migration v38 -> v39
-- Objective: Implement Deterministic Scoring Architecture
-- 1. Update health_metrics table
ALTER TABLE public.health_metrics
ADD COLUMN IF NOT EXISTS quest_points REAL DEFAULT 0.0;

-- 2. Create financial_metrics table
CREATE TABLE IF NOT EXISTS public.financial_metrics (
    id UUID NOT NULL PRIMARY KEY,
    tenant_id UUID REFERENCES public.organizations (id) ON DELETE CASCADE,
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    date DATE NOT NULL,
    quest_points REAL DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    CONSTRAINT financial_metrics_person_date_key UNIQUE (person_id, date)
);

-- 3. Create project_metrics table
CREATE TABLE IF NOT EXISTS public.project_metrics (
    id UUID NOT NULL PRIMARY KEY,
    tenant_id UUID REFERENCES public.organizations (id) ON DELETE CASCADE,
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    date DATE NOT NULL,
    quest_points REAL DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    CONSTRAINT project_metrics_person_date_key UNIQUE (person_id, date)
);

-- 4. Create social_metrics table
CREATE TABLE IF NOT EXISTS public.social_metrics (
    id UUID NOT NULL PRIMARY KEY,
    tenant_id UUID REFERENCES public.organizations (id) ON DELETE CASCADE,
    person_id UUID REFERENCES public.persons (id) ON DELETE CASCADE,
    date DATE NOT NULL,
    quest_points REAL DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT NOW (),
    CONSTRAINT social_metrics_person_date_key UNIQUE (person_id, date)
);

-- 5. Enable RLS and add basic policies (assuming tenant-based access)
ALTER TABLE public.financial_metrics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.project_metrics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.social_metrics ENABLE ROW LEVEL SECURITY;

-- Basic policy: users can see metrics for their own person/tenant records
-- (Adjust these if you have more specific RLS requirements)
CREATE POLICY "Users can view their own financial metrics" ON public.financial_metrics FOR ALL TO authenticated USING (tenant_id = auth.jwt () - > > 'tenant_id');

CREATE POLICY "Users can view their own project metrics" ON public.project_metrics FOR ALL TO authenticated USING (tenant_id = auth.jwt () - > > 'tenant_id');

CREATE POLICY "Users can view their own social metrics" ON public.social_metrics FOR ALL TO authenticated USING (tenant_id = auth.jwt () - > > 'tenant_id');

-- 6. Indices for performance
CREATE INDEX IF NOT EXISTS idx_financial_metrics_person_date ON public.financial_metrics (person_id, date);

CREATE INDEX IF NOT EXISTS idx_project_metrics_person_date ON public.project_metrics (person_id, date);

CREATE INDEX IF NOT EXISTS idx_social_metrics_person_date ON public.social_metrics (person_id, date);