-- Recurring/fixed income streams per person (salary, freelance, dividends, etc.)
CREATE TABLE IF NOT EXISTS public.recurring_incomes (
  id text PRIMARY KEY,
  person_id text NOT NULL,
  category text NOT NULL,
  amount double precision NOT NULL,
  description text,
  "interval" text NOT NULL DEFAULT 'monthly',
  next_due_at timestamptz NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_recurring_incomes_person ON public.recurring_incomes(person_id);

ALTER TABLE public.recurring_incomes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own recurring_incomes"
  ON public.recurring_incomes FOR ALL
  USING (person_id = auth.uid()::text)
  WITH CHECK (person_id = auth.uid()::text);

COMMENT ON TABLE public.recurring_incomes IS 'Fixed/recurring income streams (salary, freelance, bonus, human_capital, dividends, interest, royalties)';
COMMENT ON COLUMN public.recurring_incomes.category IS 'salary, freelance, bonus, human_capital, dividends, interest, royalties';
COMMENT ON COLUMN public.recurring_incomes."interval" IS 'weekly, monthly, or yearly';
