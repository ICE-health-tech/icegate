-- Migration for App Usage Tracking
-- Created: 2026-04-28

-- Create app_usage_history table
CREATE TABLE IF NOT EXISTS public.app_usage_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES public.persons(id) ON DELETE CASCADE,
    date TIMESTAMPTZ NOT NULL,
    sector TEXT NOT NULL,
    page_path TEXT,
    duration_minutes REAL DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT app_usage_history_unique_idx UNIQUE (person_id, date, sector, page_path)
);

-- Create app_time_spending table
CREATE TABLE IF NOT EXISTS public.app_time_spending (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES public.persons(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    sector TEXT NOT NULL,
    page_path TEXT,
    duration_minutes REAL DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.app_usage_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_time_spending ENABLE ROW LEVEL SECURITY;

-- Add RLS policies
CREATE POLICY "Users can manage own app usage history"
  ON public.app_usage_history
  FOR ALL
  USING (
    person_id IN (
      SELECT id FROM persons WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    person_id IN (
      SELECT id FROM persons WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage own app time spending"
  ON public.app_time_spending
  FOR ALL
  USING (
    person_id IN (
      SELECT id FROM persons WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    person_id IN (
      SELECT id FROM persons WHERE user_id = auth.uid()
    )
  );

-- Add to PowerSync publication
ALTER PUBLICATION powersync ADD TABLE public.app_usage_history;
ALTER PUBLICATION powersync ADD TABLE public.app_time_spending;

-- Reload schema
NOTIFY pgrst, 'reload schema';
