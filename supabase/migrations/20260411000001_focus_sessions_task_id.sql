-- Align with local Drift / PowerSync client (quest link on focus sessions).
ALTER TABLE focus_sessions ADD COLUMN IF NOT EXISTS task_id TEXT REFERENCES quests(id) ON DELETE SET NULL;
