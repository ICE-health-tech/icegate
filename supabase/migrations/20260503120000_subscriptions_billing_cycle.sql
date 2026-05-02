-- App sync sends billing_cycle (monthly | yearly); column exists in local Drift but was missing remotely.
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS billing_cycle TEXT NOT NULL DEFAULT 'monthly';

COMMENT ON COLUMN public.subscriptions.billing_cycle IS 'Billing cadence: monthly or yearly.';

-- Refresh PostgREST schema cache (fixes PGRST204 unknown column)
NOTIFY pgrst, 'reload schema';
