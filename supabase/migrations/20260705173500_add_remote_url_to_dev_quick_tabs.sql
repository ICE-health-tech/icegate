-- Remote / off-LAN URL for dev_quick_tabs (fallback when LAN is unreachable).
ALTER TABLE public.dev_quick_tabs
  ADD COLUMN IF NOT EXISTS remote_url text NOT NULL DEFAULT '';

COMMENT ON COLUMN public.dev_quick_tabs.full_url IS 'Homelab / LAN URL';
COMMENT ON COLUMN public.dev_quick_tabs.remote_url IS
  'Public or VPN URL when full_url (LAN) is unreachable';
