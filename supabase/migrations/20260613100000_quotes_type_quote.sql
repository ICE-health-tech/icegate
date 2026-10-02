-- Mind weekly topic + quote categories.

ALTER TABLE public.quotes
  ADD COLUMN IF NOT EXISTS type_quote TEXT;

CREATE INDEX IF NOT EXISTS quotes_person_type_idx
  ON public.quotes (person_id, type_quote);

COMMENT ON COLUMN public.quotes.type_quote IS
  'Quote category, e.g. focus_week for Mind dashboard weekly topic.';
