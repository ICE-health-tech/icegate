-- Phase A: Health insights — RPC for Flutter charts (apply via Supabase SQL editor or CLI).
-- Requires authenticated user; uses auth.uid() as person_id (matches app convention).

CREATE OR REPLACE FUNCTION public.get_health_steps_trend(p_days integer DEFAULT 14)
RETURNS TABLE (
  metric_date date,
  steps bigint,
  calories_burned bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT hm.date::date AS metric_date,
         COALESCE(SUM(hm.steps), 0)::bigint AS steps,
         COALESCE(SUM(hm.calories_burned), 0)::bigint AS calories_burned
  FROM public.health_metrics hm
  WHERE hm.person_id = auth.uid()
    AND hm.date >= (CURRENT_DATE - (GREATEST(p_days, 1) - 1))
  GROUP BY hm.date
  ORDER BY hm.date;
$$;

COMMENT ON FUNCTION public.get_health_steps_trend(integer) IS
  'Daily steps/calories_burned from health_metrics for the current user; used by Flutter insights.';

REVOKE ALL ON FUNCTION public.get_health_steps_trend(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_health_steps_trend(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_health_steps_trend(integer) TO service_role;
