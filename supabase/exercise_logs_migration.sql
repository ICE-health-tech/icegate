-- ════════════════════════════════════════════════════════════════
-- TABLE: exercise_logs
-- Synced via PowerSync → local Drift ExerciseLogsTable
-- Run this in: Supabase Dashboard → SQL Editor
-- ════════════════════════════════════════════════════════════════

create table public.exercise_logs (

  -- ── Identity ────────────────────────────────────────────────────
  id                  uuid          not null default gen_random_uuid(),
  tenant_id           uuid          null,
  person_id           uuid          null,

  -- ── Exercise Details ────────────────────────────────────────────
  -- type: activity name e.g. 'Running', 'Gym', 'Yoga', 'Cycling', 'Swimming'
  type                text          not null,

  -- duration_minutes: stored as a convenience cache.
  --   For timer-driven logs, prefer joining focus_sessions.duration_seconds for exact value.
  duration_minutes    integer       not null,

  -- intensity: 'low' | 'medium' | 'high'
  intensity           text          not null default 'medium',

  -- ── Link to Focus Session (timer-driven logs only) ───────────────
  -- When a user starts exercise via the FocusBlock timer, the resulting
  -- exercise_log is linked here so you can JOIN and get exact duration_seconds.
  -- NULL for manually-logged entries (from the manual add form).
  focus_session_id    uuid          null,

  -- ── Optional Enrichment ─────────────────────────────────────────
  -- calories_burned: estimated kcal computed in Flutter via estimateCalories()
  calories_burned     numeric(8,2)  null,

  -- distance_km: for running / cycling sessions
  distance_km         numeric(8,3)  null,

  -- heart_rate_avg: avg BPM if wearable data is available
  heart_rate_avg      integer       null,

  -- notes: free-text session notes
  notes               text          null,

  -- ── Linking to Health Metrics ────────────────────────────────────
  -- FK to the health_metrics row for the same day, used for aggregation joins.
  health_metric_id    uuid          null,

  -- Legacy integer id (kept for backward compat with older local records)
  log_id              integer       null,

  -- ── Timestamps ──────────────────────────────────────────────────
  -- timestamp: when the activity actually took place
  timestamp           timestamptz   not null default now(),
  created_at          timestamptz   null default now(),
  updated_at          timestamptz   null default now(),

  -- ── Constraints ─────────────────────────────────────────────────
  constraint exercise_logs_pkey
    primary key (id),

  constraint exercise_logs_tenant_id_fkey
    foreign key (tenant_id) references organizations (id) on delete cascade,

  constraint exercise_logs_person_id_fkey
    foreign key (person_id) references persons (id) on delete cascade,

  -- JOIN to focus_sessions: SET NULL on delete so exercise log
  -- is kept even if the focus session is deleted.
  constraint exercise_logs_focus_session_id_fkey
    foreign key (focus_session_id) references focus_sessions (id) on delete set null,

  constraint exercise_logs_health_metric_id_fkey
    foreign key (health_metric_id) references health_metrics (id) on delete set null,

  -- Intensity must be one of the three valid values
  constraint exercise_logs_intensity_check
    check (intensity in ('low', 'medium', 'high')),

  -- Duration must be > 0 minutes
  constraint exercise_logs_duration_positive
    check (duration_minutes > 0),

  -- Heart rate sanity check (0 = not recorded, max realistic 250 BPM)
  constraint exercise_logs_heart_rate_check
    check (heart_rate_avg is null or (heart_rate_avg >= 0 and heart_rate_avg <= 250))

) tablespace pg_default;


-- ── Indexes ──────────────────────────────────────────────────────
-- Fast daily lookup: used by HealthLogsDAO.watchDailyExerciseLogs()
-- and getDailyExerciseWithSession() (the main JOIN query)
create index idx_exercise_logs_person_timestamp
  on public.exercise_logs (person_id, timestamp desc);

-- Fast lookup for aggregation joins against health_metrics
create index idx_exercise_logs_health_metric
  on public.exercise_logs (health_metric_id)
  where health_metric_id is not null;

-- Fast lookup for JOIN with focus_sessions
create index idx_exercise_logs_focus_session
  on public.exercise_logs (focus_session_id)
  where focus_session_id is not null;


-- ── Row Level Security ────────────────────────────────────────────
alter table public.exercise_logs enable row level security;

-- Policy: users can only see and modify their own exercise logs
-- Resolves person_id via the persons table linked to auth.uid()
create policy "Users can manage own exercise logs"
  on public.exercise_logs
  for all
  using (
    person_id in (
      select id from persons where user_id = auth.uid()
    )
  )
  with check (
    person_id in (
      select id from persons where user_id = auth.uid()
    )
  );


-- ── Auto-update updated_at trigger ───────────────────────────────
-- Keeps updated_at in sync whenever a row is modified.
-- PowerSync will detect this change delta and push it to local clients.
create or replace function public.set_exercise_logs_updated_at()
returns trigger
language plpgsql
as $$
begin
  -- Set updated_at to current UTC timestamp
  new.updated_at = now();
  return new;
end;
$$;

create trigger exercise_logs_updated_at
  before update on public.exercise_logs
  for each row
  execute function public.set_exercise_logs_updated_at();


-- ── PowerSync: Add to replication publication ───────



─────────────
-- Run ONLY if you use a Postgres publication for PowerSync.
-- Skip if PowerSync is configured with a different replication strategy.
-- alter publication powersync ADD TABLE public.exercise_logs;


-- ── Verify ───────────────────────────────────────────────────────
-- Quick sanity check after running above: should return column list
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'exercise_logs'
order by ordinal_position;
