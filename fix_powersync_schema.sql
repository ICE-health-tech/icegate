-- =====================================================
-- Ice Shield: PowerSync Schema Alignment Fix
-- This script adds missing columns and tables to Supabase
-- to match the PowerSync client-side schema.
-- =====================================================

-- 1. Create organizations table
CREATE TABLE IF NOT EXISTS public.organizations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text,
    domain text,
    created_at text DEFAULT CURRENT_TIMESTAMP::text,
    updated_at text DEFAULT CURRENT_TIMESTAMP::text
);

-- 2. Add tenant_id to all tables (required by PowerSync schema)
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    LOOP
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = t AND column_name = 'tenant_id') THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN tenant_id text', t);
        END IF;
    END LOOP;
END $$;

-- 3. Fix custom_notifications table (missing several columns)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_notifications' AND column_name = 'category') THEN
        ALTER TABLE public.custom_notifications ADD COLUMN category text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_notifications' AND column_name = 'priority') THEN
        ALTER TABLE public.custom_notifications ADD COLUMN priority text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_notifications' AND column_name = 'icon') THEN
        ALTER TABLE public.custom_notifications ADD COLUMN icon text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_notifications' AND column_name = 'repeat_days') THEN
        ALTER TABLE public.custom_notifications ADD COLUMN repeat_days text;
    END IF;
END $$;

-- 4. Re-enable RLS and policies for all tables (including NEW ones)
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS "Permissive Policy" ON public.%I', t);
        EXECUTE format('CREATE POLICY "Permissive Policy" ON public.%I FOR ALL USING (true) WITH CHECK (true)', t);
    END LOOP;
END $$;

-- 5. Refresh PowerSync Publication
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR ALL TABLES;
