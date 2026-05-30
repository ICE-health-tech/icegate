-- Heart rate alert queries for n8n (Postgres node)
--
-- Use a Supabase service-role / direct Postgres connection (RLS is enabled on heart_rate_logs).
--
-- Join note: heart_rate_logs.person_id references auth.users(id), NOT user_accounts.id.
-- Link user_accounts via: hr.person_id::text = usera.person_id
--
-- Suggested n8n flow: Schedule Trigger → Postgres → IF (rows > 0) → Email/Slack
--
-- Tunable defaults:
--   bpm_high     = 100   (tachycardia at rest)
--   bpm_critical = 120
--   lookback     = 15 minutes
--   cooldown     = 60 minutes (dedupe in Query 1)

-- =============================================================================
-- Query 1 — Scheduled alerts (new high readings, cooldown dedupe)
-- =============================================================================
-- Best default for cron (every 5–15 min). Skips repeat alerts for same person
-- within the cooldown window.

WITH params AS (
  SELECT
    100  AS bpm_high,
    120  AS bpm_critical,
    interval '15 minutes' AS lookback,
    interval '60 minutes' AS cooldown
)
SELECT
  hr.id,
  hr.person_id,
  hr.bpm,
  hr.timestamp,
  hr.created_at,
  u.email AS auth_email,
  usera.username,
  usera.person_id AS account_person_id,
  CASE
    WHEN hr.bpm >= p.bpm_critical THEN 'critical'
    WHEN hr.bpm >= p.bpm_high     THEN 'high'
    ELSE 'normal'
  END AS severity,
  format(
    'Heart rate alert: %s bpm (%s) for %s at %s',
    hr.bpm,
    CASE WHEN hr.bpm >= p.bpm_critical THEN 'critical' ELSE 'high' END,
    COALESCE(usera.username, u.email, hr.person_id::text),
    to_char(hr.timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS UTC')
  ) AS alert_message
FROM public.heart_rate_logs hr
CROSS JOIN params p
LEFT JOIN auth.users u
  ON u.id = hr.person_id
LEFT JOIN public.user_accounts usera
  ON hr.person_id::text = usera.person_id
WHERE hr.bpm >= p.bpm_high
  AND hr.timestamp > now() - p.lookback
  AND hr.bpm BETWEEN 40 AND 250
  AND NOT EXISTS (
    SELECT 1
    FROM public.heart_rate_logs prev
    CROSS JOIN params p2
    WHERE prev.person_id = hr.person_id
      AND prev.bpm >= p2.bpm_high
      AND prev.id <> hr.id
      AND prev.timestamp BETWEEN hr.timestamp - p2.cooldown AND hr.timestamp
  )
ORDER BY hr.bpm DESC, hr.timestamp DESC;


-- =============================================================================
-- Query 2 — One row per person (highest BPM in window; less email spam)
-- =============================================================================

WITH params AS (
  SELECT
    100 AS bpm_high,
    interval '15 minutes' AS lookback
),
ranked AS (
  SELECT
    hr.person_id,
    hr.bpm,
    hr.timestamp,
    hr.id,
    u.email AS auth_email,
    usera.username,
    ROW_NUMBER() OVER (
      PARTITION BY hr.person_id
      ORDER BY hr.bpm DESC, hr.timestamp DESC
    ) AS rn
  FROM public.heart_rate_logs hr
  CROSS JOIN params p
  LEFT JOIN auth.users u ON u.id = hr.person_id
  LEFT JOIN public.user_accounts usera
    ON hr.person_id::text = usera.person_id
  WHERE hr.bpm >= p.bpm_high
    AND hr.timestamp > now() - p.lookback
    AND hr.bpm BETWEEN 40 AND 250
)
SELECT
  person_id,
  bpm,
  timestamp,
  id AS log_id,
  auth_email,
  username,
  COALESCE(username, auth_email, person_id::text) AS display_name,
  'heart_rate_high' AS alert_type,
  jsonb_build_object(
    'schema_version', 1,
    'report_type', 'heart_rate_alert',
    'person_id', person_id,
    'bpm', bpm,
    'timestamp', timestamp,
    'recipient_email', auth_email,
    'username', username,
    'severity', CASE WHEN bpm >= 120 THEN 'critical' ELSE 'high' END
  ) AS payload
FROM ranked
WHERE rn = 1
ORDER BY bpm DESC;


-- =============================================================================
-- Query 3 — Critical only (fewer false positives during exercise)
-- =============================================================================
-- High BPM with no other elevated readings in the prior hour (rough “at rest” proxy).

SELECT
  hr.id,
  hr.person_id,
  hr.bpm,
  hr.timestamp,
  u.email AS recipient_email,
  usera.username,
  'critical' AS severity
FROM public.heart_rate_logs hr
LEFT JOIN auth.users u ON u.id = hr.person_id
LEFT JOIN public.user_accounts usera
  ON hr.person_id::text = usera.person_id
WHERE hr.bpm >= 120
  AND hr.timestamp > now() - interval '10 minutes'
  AND NOT EXISTS (
    SELECT 1
    FROM public.heart_rate_logs earlier
    WHERE earlier.person_id = hr.person_id
      AND earlier.bpm >= 100
      AND earlier.timestamp BETWEEN hr.timestamp - interval '1 hour'
                                AND hr.timestamp - interval '2 minutes'
  )
ORDER BY hr.bpm DESC;


-- =============================================================================
-- Query 4 — Production dedupe: alert_sent ledger
-- =============================================================================
-- Run the CREATE TABLE once in Supabase SQL editor, then use SELECT + INSERT below.

-- CREATE TABLE IF NOT EXISTS public.heart_rate_alert_sent (
--   log_id uuid PRIMARY KEY,
--   person_id uuid NOT NULL,
--   bpm integer NOT NULL,
--   sent_at timestamptz NOT NULL DEFAULT now()
-- );

-- --- 4a: Find rows not yet alerted ---
SELECT
  hr.id AS log_id,
  hr.person_id,
  hr.bpm,
  hr.timestamp,
  u.email AS recipient_email,
  usera.username
FROM public.heart_rate_logs hr
LEFT JOIN auth.users u ON u.id = hr.person_id
LEFT JOIN public.user_accounts usera
  ON hr.person_id::text = usera.person_id
WHERE hr.bpm >= 100
  AND hr.timestamp > now() - interval '15 minutes'
  AND NOT EXISTS (
    SELECT 1 FROM public.heart_rate_alert_sent s
    WHERE s.log_id = hr.id
  )
ORDER BY hr.bpm DESC;

-- --- 4b: After n8n sends notification, mark as sent ---
-- Bind $1 = log_id, $2 = person_id, $3 = bpm from previous node.
--
-- INSERT INTO public.heart_rate_alert_sent (log_id, person_id, bpm)
-- VALUES ($1::uuid, $2::uuid, $3::int)
-- ON CONFLICT (log_id) DO NOTHING;
