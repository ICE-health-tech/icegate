# Context
The powersync schema:
# PowerSync Sync Rules - Edition 5 (Stability Fix)
config:
  edition: 2

bucket_definitions:
  # 1. Personal User Data
  # This bucket handles everything unique to YOU.
  user_bucket:
    parameters: SELECT request.user_id() as uid
    data:
      - SELECT * FROM persons WHERE id = bucket.uid
      - SELECT * FROM profiles WHERE person_id = bucket.uid
      - SELECT * FROM project_notes WHERE person_id = bucket.uid
      - SELECT * FROM projects WHERE person_id = bucket.uid
      - SELECT * FROM email_addresses WHERE person_id = bucket.uid
      - SELECT * FROM user_accounts WHERE person_id = bucket.uid
      - SELECT * FROM detail_information WHERE person_id = bucket.uid
      - SELECT * FROM skills WHERE person_id = bucket.uid
      - SELECT * FROM financial_accounts WHERE person_id = bucket.uid
      - SELECT * FROM assets WHERE person_id = bucket.uid
      - SELECT * FROM transactions WHERE person_id = bucket.uid
      - SELECT * FROM goals WHERE person_id = bucket.uid
      - SELECT * FROM scores WHERE person_id = bucket.uid
      - SELECT * FROM habits WHERE person_id = bucket.uid
      - SELECT * FROM person_widgets WHERE person_id = bucket.uid
      - SELECT * FROM health_metrics WHERE person_id = bucket.uid
      - SELECT * FROM water_logs WHERE person_id = bucket.uid
      - SELECT * FROM sleep_logs WHERE person_id = bucket.uid
      - SELECT * FROM exercise_logs WHERE person_id = bucket.uid
      - SELECT * FROM focus_sessions WHERE person_id = bucket.uid
      - SELECT * FROM quests WHERE person_id = bucket.uid
      - SELECT * FROM meals WHERE person_id = bucket.uid
      - SELECT * FROM sessions WHERE id = bucket.uid

  # 2. Shared Organization Data
  # This bucket handles data shared with your team/organization.
  # It only activates if you have a tenant_id assigned.
  tenant_bucket:
    parameters: SELECT tenant_id as tid FROM persons WHERE id = request.user_id()
    data:
      - SELECT * FROM internal_widgets WHERE tenant_id = bucket.tid
      - SELECT * FROM external_widgets WHERE tenant_id = bucket.tid
      - SELECT * FROM themes WHERE tenant_id = bucket.tid
      - SELECT * FROM themes_config WHERE tenant_id = bucket.tid
      - SELECT * FROM quotes WHERE tenant_id = bucket.tid
      - SELECT * FROM custom_notifications WHERE tenant_id = bucket.tid
      - SELECT * FROM days WHERE tenant_id = bucket.tid
      - SELECT * FROM organizations WHERE id = bucket.tid
      # Shared organizational scores
      - SELECT id, person_id, career_global_score, social_global_score, health_global_score, financial_global_score, updated_at FROM scores WHERE tenant_id = bucket.tid
      - SELECT id, first_name, last_name, profile_image_url FROM persons WHERE tenant_id = bucket.tid

  # 3. Global Public Data
  # Data that has no tenant and should be visible to everyone.
  global_bucket:
    data:
      - SELECT * FROM internal_widgets WHERE tenant_id IS NULL
      - SELECT * FROM external_widgets WHERE tenant_id IS NULL
      - SELECT * FROM themes WHERE tenant_id IS NULL
      - SELECT * FROM themes_config WHERE tenant_id IS NULL
      - SELECT * FROM quotes WHERE tenant_id IS NULL
      - SELECT * FROM custom_notifications WHERE tenant_id IS NULL
      - SELECT * FROM days WHERE tenant_id IS NULL
# The current Supabase schema
create table public.health_logs (
  id uuid not null default gen_random_uuid (),
  person_id integer null,
  log_type text null,
  value double precision null default 0.0,
  unit text null,
  logged_at text null default (CURRENT_TIMESTAMP)::text,
  tenant_id text null,
  constraint health_logs_pkey primary key (id)
) TABLESPACE pg_default;

create table public.health_metrics (
  id uuid not null,
  tenant_id uuid null,
  metric_id text null,
  person_id uuid null,
  date date not null,
  steps integer null default 0,
  heart_rate integer null default 0,
  sleep_hours real null default 0.0,
  water_glasses integer null default 0,
  exercise_minutes integer null default 0,
  focus_minutes integer null default 0,
  weight_kg real null default 0.0,
  calories_consumed integer null default 0,
  calories_burned integer null default 0,
  updated_at timestamp with time zone null default now(),
  quest_points double precision null default 0.0,
  category text null default 'General'::text,
  constraint health_metrics_pkey primary key (id),
  constraint health_metrics_person_id_date_category_key unique (person_id, date, category),
  constraint health_metrics_person_id_fkey foreign KEY (person_id) references persons (id) on delete CASCADE,
  constraint health_metrics_tenant_id_fkey foreign KEY (tenant_id) references organizations (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_health_metrics_person_date_category on public.health_metrics using btree (person_id, date, category) TABLESPACE pg_default;


# Issue now

Only step by today is logged, other days step are 0

# Status: Fixed (2026-04-07)

- Added `syncHistory` method to `HealthBlock` to fetch data for the last 7 days.
- Updated `StepsPage` to trigger sync automatically on init.
- Added manual sync button to `StepsPage` header.
- Redesigned `StepsDashboardPage` for better UX and consistency.
- Updated `HealthBlock` to support saving data for specific dates.
