-- Migration to fix RLS, adjust types, and setup test account

-- 0. Change public.user_accounts.person_id to UUID
-- We use 'USING person_id::uuid' to cast existing values
ALTER TABLE public.user_accounts 
ALTER COLUMN person_id TYPE uuid USING person_id::uuid;

-- 1. Fix metrics policies to use auth.uid() instead of tenant_id claim
DROP POLICY IF EXISTS "Users can view their own financial metrics" ON public.financial_metrics;
CREATE POLICY "Users can manage their own financial metrics" ON public.financial_metrics 
    FOR ALL TO authenticated 
    USING (person_id = auth.uid())
    WITH CHECK (person_id = auth.uid());

DROP POLICY IF EXISTS "Users can view their own project metrics" ON public.project_metrics;
CREATE POLICY "Users can manage their own project metrics" ON public.project_metrics 
    FOR ALL TO authenticated 
    USING (person_id = auth.uid())
    WITH CHECK (person_id = auth.uid());

DROP POLICY IF EXISTS "Users can view their own social metrics" ON public.social_metrics;
CREATE POLICY "Users can manage their own social metrics" ON public.social_metrics 
    FOR ALL TO authenticated 
    USING (person_id = auth.uid())
    WITH CHECK (person_id = auth.uid());

-- 2. Allow anonymous username resolution for login
DROP POLICY IF EXISTS "Allow anon to resolve usernames" ON public.user_accounts;
CREATE POLICY "Allow anon to resolve usernames" ON public.user_accounts 
    FOR SELECT TO anon 
    USING (true);

DROP POLICY IF EXISTS "Allow anon to resolve emails" ON public.email_addresses;
CREATE POLICY "Allow anon to resolve emails" ON public.email_addresses 
    FOR SELECT TO anon 
    USING (true);

-- 3. Ensure user_accounts has a permissive update policy for password changes
DROP POLICY IF EXISTS "Users can update their own account" ON public.user_accounts;
CREATE POLICY "Users can update their own account" ON public.user_accounts 
    FOR UPDATE TO authenticated 
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- 4. Insert Test Account
DO $$
DECLARE
    test_uid uuid := '019cc680-e55f-70f1-b174-8bbc4ce4209e'; -- Case-sensitive fix
BEGIN
    -- 1. Insert into persons
    INSERT INTO public.persons (id, first_name, last_name, is_active)
    VALUES (test_uid, 'Test', 'User', true)
    ON CONFLICT (id) DO NOTHING;

    -- 2. Insert into email_addresses
    INSERT INTO public.email_addresses (id, person_id, email_address, is_primary, status)
    VALUES (test_uid, test_uid, 'test@example.com', true, 'verified')
    ON CONFLICT (id) DO NOTHING;

    -- 3. Insert into user_accounts (person_id is now UUID)
    INSERT INTO public.user_accounts (id, person_id, username, password_hash, role)
    VALUES (test_uid, test_uid, 'testuser', 'EXTERNAL_AUTH', 'user')
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Test account metadata for testuser (test@example.com) created.';
END $$;