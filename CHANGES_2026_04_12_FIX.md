# Implementation Report: Crash Fix & Portfolio SQL
**Date:** 2026-04-12
**Issue:** `Bad state: Too many elements` in `HomePage.dart`

## 1. Bug Fix: Initialization Crash
- **Root Cause**: `InternalWidgetsTable` in Drift lacked a binary uniqueness constraint on `alias`, and `InternalWidgetsDAO` used `getSingleOrNull()` which crashes if multiple records are found. Duplicate seeding in development triggered this.
- **Resolution**: 
    - Updated `InternalWidgetsDAO` in `database.dart` to use `limit(1)` in `getInternalWidgetByAlias` and `getInternalWidgetByName`. This ensures safety even if duplicates exist.
    - Updated `_seedPlugins` in `HomePage.dart` to be more robust.

## 2. Supabase SQL: `portfolio_snapshots`
The following SQL enables the **Quant Terminal** persistence layer in the cloud.

```sql
-- 1. Create portfolio_snapshots table
CREATE TABLE IF NOT EXISTS public.portfolio_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE,
  person_id uuid REFERENCES public.persons(id) ON DELETE CASCADE,
  total_net_worth numeric NOT NULL,
  ath_at_time numeric NOT NULL,
  timestamp timestamp with time zone DEFAULT now() NOT NULL
);

-- 2. Enable Row Level Security
ALTER TABLE public.portfolio_snapshots ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies
CREATE POLICY "Users can manage their own snapshots"
ON public.portfolio_snapshots
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);

-- 4. Enable Replication for PowerSync
-- Note: Replace 'powersync_publication' with your actual publication name
ALTER PUBLICATION powersync ADD TABLE public.portfolio_snapshots;
```

## Files Modified
- `/lib/data_layer/DataSources/local_database/database.dart`
- `/lib/ui_layer/home_page/HomePage.dart`
