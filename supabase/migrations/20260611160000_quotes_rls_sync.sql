-- Wisdom board (quotes): RLS + PowerSync publication.

ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own quotes" ON public.quotes;
CREATE POLICY "Users manage own quotes"
ON public.quotes
FOR ALL
USING (auth.uid() = person_id)
WITH CHECK (auth.uid() = person_id);

CREATE INDEX IF NOT EXISTS quotes_person_created_idx
  ON public.quotes (person_id, created_at DESC);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'powersync'
  ) THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'powersync'
      AND schemaname = 'public'
      AND tablename = 'quotes'
  ) THEN
    ALTER PUBLICATION powersync ADD TABLE public.quotes;
  END IF;
END $$;

COMMENT ON TABLE public.quotes IS
  'Wisdom board quotes (Trí tuệ) — synced per person.';
