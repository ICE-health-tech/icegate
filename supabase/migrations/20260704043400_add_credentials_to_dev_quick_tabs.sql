-- Add username, password, login_type to dev_quick_tabs.
ALTER TABLE public.dev_quick_tabs ADD COLUMN IF NOT EXISTS username text NOT NULL DEFAULT '';
ALTER TABLE public.dev_quick_tabs ADD COLUMN IF NOT EXISTS password text NOT NULL DEFAULT '';
ALTER TABLE public.dev_quick_tabs ADD COLUMN IF NOT EXISTS login_type text NOT NULL DEFAULT 'html_form';

COMMENT ON COLUMN public.dev_quick_tabs.username IS 'Login username for the tab URL';
COMMENT ON COLUMN public.dev_quick_tabs.password IS 'Login password for the tab URL';
COMMENT ON COLUMN public.dev_quick_tabs.login_type IS 'Autofill strategy: html_form, email_password, api_key, http_basic, oauth, none';
