-- Table for temporary challenges
CREATE TABLE IF NOT EXISTS public.webauthn_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge TEXT NOT NULL,
    email TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + interval '5 minutes'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Table for user passkeys
CREATE TABLE IF NOT EXISTS public.user_passkeys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    credential_id TEXT NOT NULL UNIQUE,
    public_key TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index for quick challenge lookup
CREATE INDEX IF NOT EXISTS idx_webauthn_challenges_email ON public.webauthn_challenges(email);

-- Enable RLS (Row Level Security) - typically handled by service role in edge functions
ALTER TABLE public.webauthn_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_passkeys ENABLE ROW LEVEL SECURITY;
