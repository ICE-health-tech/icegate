-- Table to store screen time selection and settings across devices
CREATE TABLE IF NOT EXISTS public.screen_time_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    app_tokens TEXT[] DEFAULT '{}',
    category_tokens TEXT[] DEFAULT '{}',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(person_id)
);

-- Enable RLS
ALTER TABLE public.screen_time_settings ENABLE ROW LEVEL SECURITY;

-- Policy for users to manage their own settings
CREATE POLICY "Users can manage their own screen time settings"
ON public.screen_time_settings
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);
