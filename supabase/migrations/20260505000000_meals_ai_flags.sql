-- Migrate the local-only AI lifecycle flags onto Supabase so meal analysis
-- state syncs across devices.
--
-- `is_analyzing`   -> true while a device is actively running calorie analysis.
-- `needs_ai_retry` -> persists when an analysis attempt failed and should be
--                     retried (possibly by another device).
alter table public.meals
  add column if not exists is_analyzing boolean not null default false,
  add column if not exists needs_ai_retry boolean not null default false;

-- Partial index keeps "give me meals still needing retry for this person"
-- queries cheap without bloating storage on the common (no retry) case.
create index if not exists meals_needs_ai_retry_idx
  on public.meals (person_id)
  where needs_ai_retry = true;
