-- Health backend: GET health metrics for the authenticated user.
-- Matches Drift HealthMetricsTable / Flutter HealthInsightsRemoteService.

-- ---------------------------------------------------------------------------
-- get_health_metrics — daily rows in a date window (newest first optional)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_health_metrics(
  p_days integer DEFAULT 14,
  p_category text DEFAULT NULL
)
RETURNS TABLE (
  id text,
  person_id text,
  metric_date date,
  category text,
  steps bigint,
  heart_rate integer,
  sleep_hours double precision,
  water_glasses integer,
  exercise_minutes integer,
  focus_minutes integer,
  weight_kg double precision,
  calories_consumed integer,
  calories_burned integer,
  oxygen_saturation double precision,
  quest_points double precision,
  source text,
  updated_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    hm.id::text,
    hm.person_id::text,
    hm.date::date AS metric_date,
    hm.category,
    COALESCE(hm.steps, 0)::bigint,
    hm.heart_rate,
    hm.sleep_hours,
    hm.water_glasses,
    hm.exercise_minutes,
    hm.focus_minutes,
    hm.weight_kg,
    hm.calories_consumed,
    hm.calories_burned,
    hm.oxygen_saturation,
    hm.quest_points,
    hm.source,
    hm.updated_at
  FROM public.health_metrics hm
  WHERE hm.person_id = auth.uid()
    AND hm.date::date >= (CURRENT_DATE - (GREATEST(p_days, 1) - 1))
    AND (p_category IS NULL OR hm.category = p_category)
  ORDER BY hm.date DESC, hm.category NULLS LAST;
$$;

COMMENT ON FUNCTION public.get_health_metrics(integer, text) IS
  'Daily health_metrics rows for auth.uid() over the last p_days; optional category filter.';

REVOKE ALL ON FUNCTION public.get_health_metrics(integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_health_metrics(integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_health_metrics(integer, text) TO service_role;

-- ---------------------------------------------------------------------------
-- get_health_metrics_for_day — one calendar day
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_health_metrics_for_day(
  p_day date DEFAULT CURRENT_DATE,
  p_category text DEFAULT NULL
)
RETURNS TABLE (
  id text,
  person_id text,
  metric_date date,
  category text,
  steps bigint,
  heart_rate integer,
  sleep_hours double precision,
  water_glasses integer,
  exercise_minutes integer,
  focus_minutes integer,
  weight_kg double precision,
  calories_consumed integer,
  calories_burned integer,
  oxygen_saturation double precision,
  quest_points double precision,
  source text,
  updated_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    hm.id::text,
    hm.person_id::text,
    hm.date::date AS metric_date,
    hm.category,
    COALESCE(hm.steps, 0)::bigint,
    hm.heart_rate,
    hm.sleep_hours,
    hm.water_glasses,
    hm.exercise_minutes,
    hm.focus_minutes,
    hm.weight_kg,
    hm.calories_consumed,
    hm.calories_burned,
    hm.oxygen_saturation,
    hm.quest_points,
    hm.source,
    hm.updated_at
  FROM public.health_metrics hm
  WHERE hm.person_id = auth.uid()
    AND hm.date::date = p_day
    AND (p_category IS NULL OR hm.category = p_category)
  ORDER BY hm.category NULLS LAST;
$$;

COMMENT ON FUNCTION public.get_health_metrics_for_day(date, text) IS
  'health_metrics for auth.uid() on a single day; optional category filter.';

REVOKE ALL ON FUNCTION public.get_health_metrics_for_day(date, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_health_metrics_for_day(date, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_health_metrics_for_day(date, text) TO service_role;

-- Keep existing get_health_steps_trend (migration_v46 / prior) for charts.
