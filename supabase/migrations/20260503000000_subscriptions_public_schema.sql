-- public.subscriptions — matches FinanceDAO / Drift and PostgREST sync (.eq('person_id', ...)).
-- Runs before 20260503120000_subscriptions_billing_cycle.sql so fresh DBs get the full table first.

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid (),
  person_id uuid NULL REFERENCES public.persons (id) ON DELETE CASCADE,
  name text NOT NULL,
  amount numeric(12, 2) NOT NULL DEFAULT 0,
  billing_day integer NOT NULL,
  category text NULL,
  is_active boolean NULL DEFAULT true,
  created_at timestamp with time zone NULL DEFAULT now(),
  billing_cycle text NOT NULL DEFAULT 'monthly'::text,
  CONSTRAINT subscriptions_pkey PRIMARY KEY (id),
  CONSTRAINT subscriptions_billing_day_check CHECK (
    (billing_day >= 1) AND (billing_day <= 31)
  )
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_person_id ON public.subscriptions (person_id);

COMMENT ON TABLE public.subscriptions IS 'Finance module: recurring subscriptions (synced with local Drift).';

NOTIFY pgrst, 'reload schema';
