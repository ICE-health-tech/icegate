-- Optional mood (1-5) captured when the user logs a transaction (e.g. savings).
alter table public.transactions
  add column if not exists mood_score smallint null;

comment on column public.transactions.mood_score is
  '1-5 self-reported mood at log time; used for savings and cross-links to mind_logs.';
