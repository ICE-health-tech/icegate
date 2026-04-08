-- Migration: Add ai_model, ssh_host_id, and remote_path to projects table
-- This matches the Drift and PowerSync schema updates

ALTER TABLE projects ADD COLUMN IF NOT EXISTS ai_model text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS ssh_host_id text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS remote_path text;

-- Update the PowerSync publication if it wasn't already tracking all columns
-- Usually "FOR ALL TABLES" handles this, but explicitly ensuring it here
-- DROP PUBLICATION IF EXISTS powersync;
-- CREATE PUBLICATION powersync FOR ALL TABLES;
