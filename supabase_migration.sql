-- Migration script to update ID columns to UUID and ensure snake_case
-- 1. Update persons table
ALTER TABLE persons
ALTER COLUMN person_id TYPE UUID USING (gen_random_uuid ());

-- Note: In a real production DB with existing data, you'd need a more careful mapping
-- from the old INT IDs to the new UUIDs across all related tables.
-- Here we assume we can start fresh or use a mapping table.
-- 2. Update projects table
ALTER TABLE projects
ALTER COLUMN project_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE projects
ALTER COLUMN person_id TYPE UUID;

-- 3. Update goals table
ALTER TABLE goals
ALTER COLUMN goal_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE goals
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE goals
ALTER COLUMN project_id TYPE UUID;

-- 4. Update habits table
ALTER TABLE habits
ALTER COLUMN habit_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE habits
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE habits
ALTER COLUMN goal_id TYPE UUID;

-- 5. Update scores table
ALTER TABLE scores
ALTER COLUMN score_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE scores
ALTER COLUMN person_id TYPE UUID;

-- 6. Update skills table
ALTER TABLE skills
ALTER COLUMN skill_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE skills
ALTER COLUMN person_id TYPE UUID;

-- 7. Update financial_accounts table
ALTER TABLE financial_accounts
ALTER COLUMN account_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE financial_accounts
ALTER COLUMN person_id TYPE UUID;

-- 8. Update assets table
ALTER TABLE assets
ALTER COLUMN asset_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE assets
ALTER COLUMN person_id TYPE UUID;

-- 9. Update health_metrics table
ALTER TABLE health_metrics
ALTER COLUMN metric_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE health_metrics
ALTER COLUMN person_id TYPE UUID;

-- 10. Update person_widgets table
ALTER TABLE person_widgets
ALTER COLUMN person_widget_id TYPE UUID USING (gen_random_uuid ());

ALTER TABLE person_widgets
ALTER COLUMN person_id TYPE UUID;

-- 11. Ensure all other tables have UUID person_id
ALTER TABLE project_notes
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE project_notes
ALTER COLUMN project_id TYPE UUID;

ALTER TABLE email_addresses
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE user_accounts
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE profiles
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE detail_information
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE blog_posts
ALTER COLUMN author_id TYPE UUID;

ALTER TABLE focus_sessions
ALTER COLUMN person_id TYPE UUID;

ALTER TABLE focus_sessions
ALTER COLUMN project_id TYPE UUID;

ALTER TABLE focus_sessions
ALTER COLUMN task_id TYPE UUID;

-- 12. Primary keys for the new 'id' column (UUID)
-- If Supabase has old Primary Keys on the INT columns, they need to be dropped and recreated on 'id'.
-- For PowerSync, 'id' is the primary key and it's already a UUID.
-- Example for persons:
-- ALTER TABLE persons DROP CONSTRAINT persons_pkey CASCADE;
-- ALTER TABLE persons ADD PRIMARY KEY (id);