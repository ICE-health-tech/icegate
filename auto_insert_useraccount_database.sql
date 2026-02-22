CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  new_person_serial int;
  new_email_id uuid;
BEGIN
  -- 1. Insert/Update into persons
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

  -- 2. Insert email ONLY IF it doesn't exist
  INSERT INTO public.email_addresses (person_id, email_address, is_primary, status)
  VALUES (
    new_person_serial,
    new.email,
    true, 
    'verified'
  )
  ON CONFLICT (person_id, email_address) DO UPDATE SET email_address = EXCLUDED.email_address
  RETURNING id INTO new_email_id;

  -- 3. Ensure profile exists
  INSERT INTO public.profiles (id, person_id, bio)
  VALUES (
    new.id,
    new_person_serial,
    'Securing the digital frontier.'
  )
  ON CONFLICT (id) DO NOTHING;

  -- 4. NEW: Ensure user_account exists!
  INSERT INTO public.user_accounts (person_id, username, role, is_locked)
  VALUES (
    new_person_serial,
    new.email, -- or new.raw_user_meta_data->>'user_name' if you prefer
    'user',
    0
  )
  ON CONFLICT (username) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- (Optional) If you already have users who are missing a user_accounts row, run this:
INSERT INTO public.user_accounts (person_id, username, role, is_locked, created_at)
SELECT person_id, first_name || person_id::text, 'user', 0, CURRENT_TIMESTAMP::text
FROM public.persons p
WHERE NOT EXISTS (SELECT 1 FROM public.user_accounts u WHERE u.person_id = p.person_id);
