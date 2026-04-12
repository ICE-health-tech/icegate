-- Tag exercise-timer focus rows (client sets to 'health-exercise').
ALTER TABLE focus_sessions ADD COLUMN IF NOT EXISTS categories TEXT;
