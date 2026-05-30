# Insights & charts

## Shipped (phase A)

- **SQL:** `docs/MIGRATIONS/migration_v46_health_insights_rpc.sql` — `get_health_steps_trend(p_days)` returns daily `steps` / `calories_burned` for `auth.uid()` from `health_metrics`.
- **Dart:** `lib/orchestration_layer/Services/Health/HealthInsightsRemoteService.dart`
- **UI:** `lib/sensor_layer/ui_layer/health_page/widgets/health_remote_trend_card.dart` (`fl_chart`)
- **Screen:** `PageHealthAnalysis` — “Cloud trend” card after weekly trends when signed in and RPC returns data.

Apply the migration in the Supabase SQL editor (or your migration pipeline) before expecting the card to show cloud data.

## Next phases

- More RPCs (meals, mind logs); optional Drift cache of last RPC result; enable RLS on `health_metrics` if needed.
