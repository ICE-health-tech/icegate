-- Add email column to user_passkeys for easier lookup during authentication
ALTER TABLE public.user_passkeys ADD COLUMN IF NOT EXISTS email TEXT;

-- Index for quick lookup during login
CREATE INDEX IF NOT EXISTS idx_user_passkeys_email ON public.user_passkeys(email);
