-- Bearer token / API key for dev_quick_tabs (synced across devices).
ALTER TABLE public.dev_quick_tabs
  ADD COLUMN IF NOT EXISTS passkey text NOT NULL DEFAULT '';

COMMENT ON COLUMN public.dev_quick_tabs.passkey IS
  'API key or bearer token when login_type is api_key or bearer_token';

COMMENT ON COLUMN public.dev_quick_tabs.login_type IS
  'Autofill strategy: html_form, email_password, http_basic, api_key, bearer_token, external_browser, oauth, none';
