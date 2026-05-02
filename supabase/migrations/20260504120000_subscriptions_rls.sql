-- Row Level Security for public.subscriptions (client sync uses anon JWT → authenticated + person_id match).
-- Fixes: PostgrestException 42501 "new row violates row-level security policy"

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own subscriptions" ON public.subscriptions;

CREATE POLICY "Users can manage their own subscriptions"
  ON public.subscriptions
  FOR ALL
  TO authenticated
  USING (person_id = auth.uid())
  WITH CHECK (person_id = auth.uid());

NOTIFY pgrst, 'reload schema';
