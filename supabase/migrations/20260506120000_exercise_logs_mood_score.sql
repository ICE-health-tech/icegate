-- Optional 1–5 mood scale on exercise logs (manual entry / sync).
ALTER TABLE public.exercise_logs
  ADD COLUMN IF NOT EXISTS mood_score smallint;

COMMENT ON COLUMN public.exercise_logs.mood_score IS 'Optional 1–5 mood after activity (matches finance savings mood scale).';
