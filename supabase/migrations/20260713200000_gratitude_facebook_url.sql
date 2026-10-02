-- Facebook profile link on gratitude person entries (avatar stays local).
ALTER TABLE public.gratitude_entries
  ADD COLUMN IF NOT EXISTS facebook_url text;
