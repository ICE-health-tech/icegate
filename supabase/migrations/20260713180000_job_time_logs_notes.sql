-- Optional notes on each job time log (timer / manual log).
ALTER TABLE public.job_time_logs
  ADD COLUMN IF NOT EXISTS notes text;
