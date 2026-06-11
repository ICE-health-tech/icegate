-- One row per person + provider (calendar, health, documents, automation).
CREATE TABLE IF NOT EXISTS public.integration_accounts (
  id uuid PRIMARY KEY,
  person_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  domain text NOT NULL,
  provider text NOT NULL,
  status text NOT NULL DEFAULT 'disconnected',
  display_name text NOT NULL DEFAULT '',
  external_account_id text,
  config_json text,
  last_sync_at timestamptz,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT integration_accounts_person_domain_provider_key
    UNIQUE (person_id, domain, provider)
);

ALTER TABLE public.integration_accounts
  DROP CONSTRAINT IF EXISTS integration_accounts_domain_check;

ALTER TABLE public.integration_accounts
  ADD CONSTRAINT integration_accounts_domain_check
  CHECK (domain IN ('calendar', 'health', 'documents', 'automation'));

ALTER TABLE public.integration_accounts
  DROP CONSTRAINT IF EXISTS integration_accounts_provider_check;

ALTER TABLE public.integration_accounts
  ADD CONSTRAINT integration_accounts_provider_check
  CHECK (provider IN (
    'google_calendar',
    'apple_device_calendar',
    'android_device_calendar',
    'apple_health',
    'huawei_health',
    'google_fit',
    'google_drive',
    'notion',
    'cursor'
  ));

ALTER TABLE public.integration_accounts
  DROP CONSTRAINT IF EXISTS integration_accounts_status_check;

ALTER TABLE public.integration_accounts
  ADD CONSTRAINT integration_accounts_status_check
  CHECK (status IN ('connected', 'disconnected', 'error', 'needsReauth'));

ALTER TABLE public.integration_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS integration_accounts_select_own ON public.integration_accounts;
CREATE POLICY integration_accounts_select_own
  ON public.integration_accounts FOR SELECT
  USING (auth.uid() = person_id);

DROP POLICY IF EXISTS integration_accounts_insert_own ON public.integration_accounts;
CREATE POLICY integration_accounts_insert_own
  ON public.integration_accounts FOR INSERT
  WITH CHECK (auth.uid() = person_id);

DROP POLICY IF EXISTS integration_accounts_update_own ON public.integration_accounts;
CREATE POLICY integration_accounts_update_own
  ON public.integration_accounts FOR UPDATE
  USING (auth.uid() = person_id);

DROP POLICY IF EXISTS integration_accounts_delete_own ON public.integration_accounts;
CREATE POLICY integration_accounts_delete_own
  ON public.integration_accounts FOR DELETE
  USING (auth.uid() = person_id);

CREATE INDEX IF NOT EXISTS integration_accounts_person_id_idx
  ON public.integration_accounts (person_id);

COMMENT ON TABLE public.integration_accounts IS
  'Connection hub: one row per integration type (google_calendar, notion, google_drive, …).';
