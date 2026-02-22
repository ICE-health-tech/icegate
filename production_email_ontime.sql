-- 1. Delete existing duplicates (keep only the first one)
DELETE FROM public.email_addresses a
USING public.email_addresses b
WHERE a.id > b.id 
  AND a.person_id = b.person_id 
  AND a.email_address = b.email_address;

-- 2. Add a unique constraint to prevent this from ever happening again
ALTER TABLE public.email_addresses 
ADD CONSTRAINT unique_person_email UNIQUE (person_id, email_address);

-- 3. Update the Trigger Function to use "ON CONFLICT"
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  new_person_serial int;
BEGIN
  -- Insert/Update into persons
  INSERT INTO public.persons (id, first_name, last_name, profile_image_url, is_active)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'IceUser'),
    '' , -- Last name logic if needed
    new.raw_user_meta_data->>'avatar_url',
    1
  )
  ON CONFLICT (id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    profile_image_url = EXCLUDED.profile_image_url,
    updated_at = CURRENT_TIMESTAMP::text
  RETURNING person_id INTO new_person_serial;

  -- Insert email ONLY IF it doesn't exist (Fixes the duplication)
  INSERT INTO public.email_addresses (person_id, email_address, is_primary, status)
  VALUES (
    new_person_serial,
    new.email,
    true, -- Using boolean as in your production.sql
    'verified'
  )
  ON CONFLICT (person_id, email_address) DO NOTHING;

  -- Ensure profile exists
  INSERT INTO public.profiles (id, person_id, bio)
  VALUES (
    new.id,
    new_person_serial,
    'Securing the digital frontier.'
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
