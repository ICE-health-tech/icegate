-- Migration to create the portfolio_snapshots table

CREATE TABLE IF NOT EXISTS public.portfolio_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    person_id UUID REFERENCES public.persons(id) ON DELETE CASCADE,
    total_net_worth REAL NOT NULL DEFAULT 0.0,
    ath_at_time REAL NOT NULL DEFAULT 0.0,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Turn on RLS
ALTER TABLE public.portfolio_snapshots ENABLE ROW LEVEL SECURITY;

-- If you only want users to access their own records, add a policy
CREATE POLICY "Users can insert their own portfolio snapshots." 
    ON public.portfolio_snapshots FOR INSERT 
    WITH CHECK (auth.uid() = person_id);

CREATE POLICY "Users can view their own portfolio snapshots." 
    ON public.portfolio_snapshots FOR SELECT 
    USING (auth.uid() = person_id);

CREATE POLICY "Users can update their own portfolio snapshots." 
    ON public.portfolio_snapshots FOR UPDATE 
    USING (auth.uid() = person_id);

CREATE POLICY "Users can delete their own portfolio snapshots." 
    ON public.portfolio_snapshots FOR DELETE 
    USING (auth.uid() = person_id);

-- Explicitly add table to the PowerSync publication (so it gets synced locally)
ALTER PUBLICATION powersync ADD TABLE public.portfolio_snapshots;

-- Reload schema cache to fix PGRST205 errors
NOTIFY pgrst, 'reload schema';
