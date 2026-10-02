-- Remote schema snapshot (introspected via Supabase API)
-- Project: ice_gate (ref: wthislkepfufkbgiqegs)
-- Generated: 2026-05-04 23:53:18 UTC
--
-- This is a best-effort reconstruction from table/column metadata.
-- It does not include: RLS policies, CHECK constraints, sequences owned-by,
-- indexes, triggers, extensions, or GRANTs. Use `supabase db dump` for a
-- full pg_dump if you have the CLI linked to this project.
--

-- Table: auth.audit_log_entries  (rls_enabled=True, rows≈0)
-- Auth: Audit trail for user actions.
CREATE TABLE "auth"."audit_log_entries" (
  "instance_id" uuid,
  "id" uuid NOT NULL,
  "payload" json,
  "created_at" timestamp with time zone,
  "ip_address" character varying NOT NULL DEFAULT ''::character varying,
  PRIMARY KEY ("id")
);

-- Table: auth.custom_oauth_providers  (rls_enabled=False, rows≈0)
CREATE TABLE "auth"."custom_oauth_providers" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "provider_type" text NOT NULL,
  "identifier" text NOT NULL,
  "name" text NOT NULL,
  "client_id" text NOT NULL,
  "client_secret" text NOT NULL,
  "acceptable_client_ids" text[] NOT NULL DEFAULT '{}'::text[],
  "scopes" text[] NOT NULL DEFAULT '{}'::text[],
  "pkce_enabled" boolean NOT NULL DEFAULT true,
  "attribute_mapping" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "authorization_params" jsonb NOT NULL DEFAULT '{}'::jsonb,
  "enabled" boolean NOT NULL DEFAULT true,
  "email_optional" boolean NOT NULL DEFAULT false,
  "issuer" text,
  "discovery_url" text,
  "skip_nonce_check" boolean NOT NULL DEFAULT false,
  "cached_discovery" jsonb,
  "discovery_cached_at" timestamp with time zone,
  "authorization_url" text,
  "token_url" text,
  "userinfo_url" text,
  "jwks_uri" text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: auth.flow_state  (rls_enabled=True, rows≈235)
-- Stores metadata for all OAuth/SSO login flows
CREATE TABLE "auth"."flow_state" (
  "id" uuid NOT NULL,
  "user_id" uuid,
  "auth_code" text,
  "code_challenge_method" auth.code_challenge_method,
  "code_challenge" text,
  "provider_type" text NOT NULL,
  "provider_access_token" text,
  "provider_refresh_token" text,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "authentication_method" text NOT NULL,
  "auth_code_issued_at" timestamp with time zone,
  "invite_token" text,
  "referrer" text,
  "oauth_client_state_id" uuid,
  "linking_target_id" uuid,
  "email_optional" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("id")
);

-- Table: auth.identities  (rls_enabled=True, rows≈7)
-- Auth: Stores identities associated to a user.
CREATE TABLE "auth"."identities" (
  "provider_id" text NOT NULL,
  "user_id" uuid NOT NULL,
  "identity_data" jsonb NOT NULL,
  "provider" text NOT NULL,
  "last_sign_in_at" timestamp with time zone,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "email" text DEFAULT lower((identity_data ->> 'email'::text)),
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  PRIMARY KEY ("id")
);

-- Table: auth.instances  (rls_enabled=True, rows≈0)
-- Auth: Manages users across multiple sites.
CREATE TABLE "auth"."instances" (
  "id" uuid NOT NULL,
  "uuid" uuid,
  "raw_base_config" text,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  PRIMARY KEY ("id")
);

-- Table: auth.mfa_amr_claims  (rls_enabled=True, rows≈75)
-- auth: stores authenticator method reference claims for multi factor authentication
CREATE TABLE "auth"."mfa_amr_claims" (
  "session_id" uuid NOT NULL,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  "authentication_method" text NOT NULL,
  "id" uuid NOT NULL,
  PRIMARY KEY ("id")
);

-- Table: auth.mfa_challenges  (rls_enabled=True, rows≈0)
-- auth: stores metadata about challenge requests made
CREATE TABLE "auth"."mfa_challenges" (
  "id" uuid NOT NULL,
  "factor_id" uuid NOT NULL,
  "created_at" timestamp with time zone NOT NULL,
  "verified_at" timestamp with time zone,
  "ip_address" inet NOT NULL,
  "otp_code" text,
  "web_authn_session_data" jsonb,
  PRIMARY KEY ("id")
);

-- Table: auth.mfa_factors  (rls_enabled=True, rows≈0)
-- auth: stores metadata about factors
CREATE TABLE "auth"."mfa_factors" (
  "id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "friendly_name" text,
  "factor_type" auth.factor_type NOT NULL,
  "status" auth.factor_status NOT NULL,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  "secret" text,
  "phone" text,
  "last_challenged_at" timestamp with time zone,
  "web_authn_credential" jsonb,
  "web_authn_aaguid" uuid,
  "last_webauthn_challenge_data" jsonb,
  PRIMARY KEY ("id")
);

-- Table: auth.oauth_authorizations  (rls_enabled=False, rows≈0)
CREATE TABLE "auth"."oauth_authorizations" (
  "id" uuid NOT NULL,
  "authorization_id" text NOT NULL,
  "client_id" uuid NOT NULL,
  "user_id" uuid,
  "redirect_uri" text NOT NULL,
  "scope" text NOT NULL,
  "state" text,
  "resource" text,
  "code_challenge" text,
  "code_challenge_method" auth.code_challenge_method,
  "response_type" auth.oauth_response_type NOT NULL DEFAULT 'code'::auth.oauth_response_type,
  "status" auth.oauth_authorization_status NOT NULL DEFAULT 'pending'::auth.oauth_authorization_status,
  "authorization_code" text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "expires_at" timestamp with time zone NOT NULL DEFAULT (now() + '00:03:00'::interval),
  "approved_at" timestamp with time zone,
  "nonce" text,
  PRIMARY KEY ("id")
);

-- Table: auth.oauth_client_states  (rls_enabled=False, rows≈0)
-- Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.
CREATE TABLE "auth"."oauth_client_states" (
  "id" uuid NOT NULL,
  "provider_type" text NOT NULL,
  "code_verifier" text,
  "created_at" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id")
);

-- Table: auth.oauth_clients  (rls_enabled=False, rows≈0)
CREATE TABLE "auth"."oauth_clients" (
  "id" uuid NOT NULL,
  "client_secret_hash" text,
  "registration_type" auth.oauth_registration_type NOT NULL,
  "redirect_uris" text NOT NULL,
  "grant_types" text NOT NULL,
  "client_name" text,
  "client_uri" text,
  "logo_uri" text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  "deleted_at" timestamp with time zone,
  "client_type" auth.oauth_client_type NOT NULL DEFAULT 'confidential'::auth.oauth_client_type,
  "token_endpoint_auth_method" text NOT NULL,
  PRIMARY KEY ("id")
);

-- Table: auth.oauth_consents  (rls_enabled=False, rows≈0)
CREATE TABLE "auth"."oauth_consents" (
  "id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "client_id" uuid NOT NULL,
  "scopes" text NOT NULL,
  "granted_at" timestamp with time zone NOT NULL DEFAULT now(),
  "revoked_at" timestamp with time zone,
  PRIMARY KEY ("id")
);

-- Table: auth.one_time_tokens  (rls_enabled=True, rows≈2)
CREATE TABLE "auth"."one_time_tokens" (
  "id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "token_type" auth.one_time_token_type NOT NULL,
  "token_hash" text NOT NULL,
  "relates_to" text NOT NULL,
  "created_at" timestamp without time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp without time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: auth.refresh_tokens  (rls_enabled=True, rows≈115)
-- Auth: Store of tokens used to refresh JWT tokens once they expire.
CREATE TABLE "auth"."refresh_tokens" (
  "instance_id" uuid,
  "id" bigint NOT NULL DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass),
  "token" character varying,
  "user_id" character varying,
  "revoked" boolean,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "parent" character varying,
  "session_id" uuid,
  PRIMARY KEY ("id")
);

-- Table: auth.saml_providers  (rls_enabled=True, rows≈0)
-- Auth: Manages SAML Identity Provider connections.
CREATE TABLE "auth"."saml_providers" (
  "id" uuid NOT NULL,
  "sso_provider_id" uuid NOT NULL,
  "entity_id" text NOT NULL,
  "metadata_xml" text NOT NULL,
  "metadata_url" text,
  "attribute_mapping" jsonb,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "name_id_format" text,
  PRIMARY KEY ("id")
);

-- Table: auth.saml_relay_states  (rls_enabled=True, rows≈0)
-- Auth: Contains SAML Relay State information for each Service Provider initiated login.
CREATE TABLE "auth"."saml_relay_states" (
  "id" uuid NOT NULL,
  "sso_provider_id" uuid NOT NULL,
  "request_id" text NOT NULL,
  "for_email" text,
  "redirect_to" text,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "flow_state_id" uuid,
  PRIMARY KEY ("id")
);

-- Table: auth.schema_migrations  (rls_enabled=True, rows≈76)
-- Auth: Manages updates to the auth system.
CREATE TABLE "auth"."schema_migrations" (
  "version" character varying NOT NULL,
  PRIMARY KEY ("version")
);

-- Table: auth.sessions  (rls_enabled=True, rows≈75)
-- Auth: Stores session data associated to a user.
CREATE TABLE "auth"."sessions" (
  "id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "factor_id" uuid,
  "aal" auth.aal_level,
  "not_after" timestamp with time zone,
  "refreshed_at" timestamp without time zone,
  "user_agent" text,
  "ip" inet,
  "tag" text,
  "oauth_client_id" uuid,
  "refresh_token_hmac_key" text,
  "refresh_token_counter" bigint,
  "scopes" text,
  PRIMARY KEY ("id")
);

-- Table: auth.sso_domains  (rls_enabled=True, rows≈0)
-- Auth: Manages SSO email address domain mapping to an SSO Identity Provider.
CREATE TABLE "auth"."sso_domains" (
  "id" uuid NOT NULL,
  "sso_provider_id" uuid NOT NULL,
  "domain" text NOT NULL,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  PRIMARY KEY ("id")
);

-- Table: auth.sso_providers  (rls_enabled=True, rows≈0)
-- Auth: Manages SSO identity provider information; see saml_providers for SAML.
CREATE TABLE "auth"."sso_providers" (
  "id" uuid NOT NULL,
  "resource_id" text,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "disabled" boolean,
  PRIMARY KEY ("id")
);

-- Table: auth.users  (rls_enabled=True, rows≈7)
-- Auth: Stores user login data within a secure schema.
CREATE TABLE "auth"."users" (
  "instance_id" uuid,
  "id" uuid NOT NULL,
  "aud" character varying,
  "role" character varying,
  "email" character varying,
  "encrypted_password" character varying,
  "email_confirmed_at" timestamp with time zone,
  "invited_at" timestamp with time zone,
  "confirmation_token" character varying,
  "confirmation_sent_at" timestamp with time zone,
  "recovery_token" character varying,
  "recovery_sent_at" timestamp with time zone,
  "email_change_token_new" character varying,
  "email_change" character varying,
  "email_change_sent_at" timestamp with time zone,
  "last_sign_in_at" timestamp with time zone,
  "raw_app_meta_data" jsonb,
  "raw_user_meta_data" jsonb,
  "is_super_admin" boolean,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  "phone" text DEFAULT NULL::character varying,
  "phone_confirmed_at" timestamp with time zone,
  "phone_change" text DEFAULT ''::character varying,
  "phone_change_token" character varying DEFAULT ''::character varying,
  "phone_change_sent_at" timestamp with time zone,
  "confirmed_at" timestamp with time zone DEFAULT LEAST(email_confirmed_at, phone_confirmed_at),
  "email_change_token_current" character varying DEFAULT ''::character varying,
  "email_change_confirm_status" smallint DEFAULT 0,
  "banned_until" timestamp with time zone,
  "reauthentication_token" character varying DEFAULT ''::character varying,
  "reauthentication_sent_at" timestamp with time zone,
  "is_sso_user" boolean NOT NULL DEFAULT false,
  "deleted_at" timestamp with time zone,
  "is_anonymous" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("id")
);

-- Table: auth.webauthn_challenges  (rls_enabled=False, rows≈0)
CREATE TABLE "auth"."webauthn_challenges" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid,
  "challenge_type" text NOT NULL,
  "session_data" jsonb NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "expires_at" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id")
);

-- Table: auth.webauthn_credentials  (rls_enabled=False, rows≈0)
CREATE TABLE "auth"."webauthn_credentials" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "credential_id" bytea NOT NULL,
  "public_key" bytea NOT NULL,
  "attestation_type" text NOT NULL DEFAULT ''::text,
  "aaguid" uuid,
  "sign_count" bigint NOT NULL DEFAULT 0,
  "transports" jsonb NOT NULL DEFAULT '[]'::jsonb,
  "backup_eligible" boolean NOT NULL DEFAULT false,
  "backed_up" boolean NOT NULL DEFAULT false,
  "friendly_name" text NOT NULL DEFAULT ''::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  "last_used_at" timestamp with time zone,
  PRIMARY KEY ("id")
);

-- Table: public.achievements  (rls_enabled=False, rows≈2)
CREATE TABLE "public"."achievements" (
  "tenant_id" text,
  "person_id" text,
  "title" text,
  "description" text,
  "domain" text,
  "meaning_score" integer,
  "impact_score" integer,
  "impact_desc_who" text,
  "impact_desc_how" text,
  "created_at" text,
  "updated_at" text,
  "id" text NOT NULL,
  "mood_pre" text,
  "mood_post" text,
  PRIMARY KEY ("id")
);

-- Table: public.ai_analysis  (rls_enabled=True, rows≈25)
-- Stores periodic deep-dive AI analysis and system evaluations for the Hunter.
CREATE TABLE "public"."ai_analysis" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "person_id" uuid,
  "title" text NOT NULL,
  "summary" text,
  "detailed_analysis" text NOT NULL,
  "status" text DEFAULT 'draft'::text,
  "is_featured" boolean DEFAULT false,
  "published_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "category" text,
  "ai_model" text,
  "prompt_context" text,
  "sentiment_score" real,
  PRIMARY KEY ("id")
);

-- Table: public.app_usage_history  (rls_enabled=True, rows≈0)
CREATE TABLE "public"."app_usage_history" (
  "id" text NOT NULL,
  "person_id" text NOT NULL,
  "date" timestamp with time zone NOT NULL,
  "sector" text NOT NULL,
  "page_path" text,
  "duration_minutes" double precision NOT NULL DEFAULT 0.0,
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.assets  (rls_enabled=True, rows≈0)
-- High-value items, gear, and properties owned by the Hunter.
CREATE TABLE "public"."assets" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "asset_id" text,
  "person_id" uuid,
  "asset_name" text NOT NULL,
  "asset_category" text NOT NULL,
  "purchase_date" timestamp with time zone,
  "purchase_price" real,
  "current_estimated_value" real,
  "currency" text DEFAULT 'USD'::text,
  "condition" text DEFAULT 'good'::text,
  "location" text,
  "notes" text,
  "is_insured" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.custom_notifications  (rls_enabled=True, rows≈0)
-- Scheduled alerts and pings from the System to the Hunter.
CREATE TABLE "public"."custom_notifications" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "notification_id" text,
  "title" text NOT NULL,
  "content" text NOT NULL,
  "scheduled_time" timestamp with time zone NOT NULL,
  "repeat_frequency" text DEFAULT 'none'::text,
  "repeat_days" text,
  "is_enabled" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT now(),
  "category" text DEFAULT 'General'::text,
  "priority" text DEFAULT 'Normal'::text,
  "icon" text,
  "person_id" uuid,
  "updated_at" timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY ("id")
);

-- Table: public.days  (rls_enabled=True, rows≈7)
-- Daily summary aggregates for weight and calorie flow.
CREATE TABLE "public"."days" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "day_id" date NOT NULL,
  "weight" integer DEFAULT 0,
  "calories_out" integer DEFAULT 0,
  PRIMARY KEY ("id")
);

-- Table: public.detail_information  (rls_enabled=True, rows≈2)
-- Extended CV and professional background of the Hunter.
CREATE TABLE "public"."detail_information" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "cv_address_id" text,
  "person_id" uuid,
  "github_url" text,
  "website_url" text,
  "company" text,
  "university" text,
  "location" text,
  "country" text,
  "bio" text,
  "occupation" text,
  "education_level" text,
  "linkedin_url" text,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "cover_image_url" text,
  PRIMARY KEY ("id")
);

-- Table: public.email_addresses  (rls_enabled=True, rows≈6)
-- Contact details linked to the Hunter identity.
CREATE TABLE "public"."email_addresses" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "email_address_id" text,
  "person_id" uuid,
  "email_address" text NOT NULL,
  "email_type" text DEFAULT 'personal'::text,
  "is_primary" boolean DEFAULT false,
  "status" text DEFAULT 'pending'::text,
  "verified_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.exercise_logs  (rls_enabled=True, rows≈11)
CREATE TABLE "public"."exercise_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "person_id" uuid,
  "type" text NOT NULL,
  "duration_minutes" integer NOT NULL,
  "intensity" text NOT NULL DEFAULT 'medium'::text,
  "focus_session_id" uuid,
  "calories_burned" numeric,
  "distance_km" numeric,
  "heart_rate_avg" integer,
  "notes" text,
  "health_metric_id" uuid,
  "log_id" integer,
  "timestamp" timestamp with time zone NOT NULL DEFAULT now(),
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "session_id" text,
  "mood_score" smallint,
  PRIMARY KEY ("id")
);

-- Table: public.external_widgets  (rls_enabled=True, rows≈0)
-- Link for web app
CREATE TABLE "public"."external_widgets" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "widget_id" text,
  "name" text,
  "alias" text,
  "protocol" text,
  "host" text,
  "url" text,
  "image_url" text,
  "date_added" text,
  "person_id" text,
  PRIMARY KEY ("id")
);

-- Table: public.financial_accounts  (rls_enabled=True, rows≈0)
-- Inventories and vaults where the Hunter's currency is stored.
CREATE TABLE "public"."financial_accounts" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "account_id" text,
  "person_id" uuid,
  "account_name" text NOT NULL,
  "account_type" text DEFAULT 'checking'::text,
  "balance" real DEFAULT 0.0,
  "currency" text DEFAULT 'USD'::text,
  "is_primary" boolean DEFAULT false,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.financial_metrics  (rls_enabled=True, rows≈0)
CREATE TABLE "public"."financial_metrics" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "metric_id" text,
  "person_id" uuid,
  "date" date NOT NULL,
  "total_balance" double precision DEFAULT 0.0,
  "total_savings" double precision DEFAULT 0.0,
  "total_investments" double precision DEFAULT 0.0,
  "daily_expenses" double precision DEFAULT 0.0,
  "quest_points" double precision DEFAULT 0.0,
  "updated_at" timestamp with time zone DEFAULT now(),
  "category" text DEFAULT 'General'::text,
  PRIMARY KEY ("id")
);

-- Table: public.focus_sessions  (rls_enabled=True, rows≈31)
-- Deep-dive work sessions (Flow State) tracking duration and task linkage.
CREATE TABLE "public"."focus_sessions" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "person_id" uuid,
  "project_id" uuid,
  "start_time" timestamp with time zone NOT NULL,
  "end_time" timestamp with time zone,
  "duration_seconds" integer NOT NULL,
  "status" text NOT NULL,
  "task_id" uuid,
  "notes" text,
  "categories" text,
  "created_at" text,
  "updated_at" text,
  "session_type" text DEFAULT 'Focus'::text,
  PRIMARY KEY ("id")
);

-- Table: public.goals  (rls_enabled=True, rows≈24)
-- Major milestones or Boss Raids the Hunter is striving for.
CREATE TABLE "public"."goals" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "goal_id" text,
  "person_id" uuid,
  "title" text NOT NULL,
  "description" text,
  "category" text DEFAULT 'personal'::text,
  "priority" integer DEFAULT 3,
  "status" text DEFAULT 'active'::text,
  "target_date" timestamp with time zone,
  "completion_date" timestamp with time zone,
  "progress_percentage" integer DEFAULT 0,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "project_id" uuid,
  PRIMARY KEY ("id")
);

-- Table: public.habits  (rls_enabled=True, rows≈0)
-- Daily/Weekly recurring tasks designed to build the Hunter's base stats.
CREATE TABLE "public"."habits" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "habit_id" text,
  "person_id" uuid,
  "goal_id" uuid,
  "habit_name" text NOT NULL,
  "description" text,
  "frequency" text NOT NULL,
  "frequency_details" text,
  "target_count" integer DEFAULT 1,
  "is_active" boolean DEFAULT true,
  "started_date" timestamp with time zone DEFAULT now(),
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.health_logs  (rls_enabled=True, rows≈0)
CREATE TABLE "public"."health_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "person_id" integer,
  "log_type" text,
  "value" double precision DEFAULT 0.0,
  "unit" text,
  "logged_at" text DEFAULT (CURRENT_TIMESTAMP)::text,
  "tenant_id" text,
  PRIMARY KEY ("id")
);

-- Table: public.health_metrics  (rls_enabled=False, rows≈136)
CREATE TABLE "public"."health_metrics" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "metric_id" text,
  "person_id" uuid,
  "date" date NOT NULL,
  "steps" integer DEFAULT 0,
  "heart_rate" integer DEFAULT 0,
  "sleep_hours" double precision DEFAULT 0.0,
  "water_glasses" integer DEFAULT 0,
  "exercise_minutes" integer DEFAULT 0,
  "weight_kg" double precision DEFAULT 0.0,
  "calories_consumed" integer DEFAULT 0,
  "calories_burned" integer DEFAULT 0,
  "focus_minutes" integer DEFAULT 0,
  "quest_points" double precision DEFAULT 0.0,
  "category" text,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "oxygen_saturation" double precision,
  "source" text,
  PRIMARY KEY ("id")
);

-- Table: public.heart_rate_logs  (rls_enabled=True, rows≈2212)
CREATE TABLE "public"."heart_rate_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid DEFAULT '00000000-0000-0000-0000-000000000001'::uuid,
  "person_id" uuid,
  "bpm" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.hourly_activity_log  (rls_enabled=False, rows≈600)
CREATE TABLE "public"."hourly_activity_log" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "person_id" uuid,
  "start_time" timestamp with time zone NOT NULL,
  "end_time" timestamp with time zone,
  "log_date" date NOT NULL,
  "steps_count" integer DEFAULT 0,
  "distance_km" double precision DEFAULT 0.0,
  "calories_burned" integer DEFAULT 0,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.internal_widgets  (rls_enabled=True, rows≈91)
-- System UI components native to the application.
CREATE TABLE "public"."internal_widgets" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "widget_id" text,
  "name" text,
  "url" text,
  "date_added" text,
  "image_url" text,
  "alias" text,
  "person_id" text,
  "scope" text,
  PRIMARY KEY ("id")
);

-- Table: public.meals  (rls_enabled=True, rows≈0)
-- Consumables used to restore energy or modify temporary stats.
CREATE TABLE "public"."meals" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "meal_id" text,
  "person_id" uuid,
  "meal_name" text NOT NULL,
  "meal_image_url" text,
  "fat" real DEFAULT 0.0,
  "carbs" real DEFAULT 0.0,
  "protein" real DEFAULT 0.0,
  "calories" real DEFAULT 0.0,
  "eaten_at" timestamp with time zone DEFAULT now(),
  "is_analyzing" boolean NOT NULL DEFAULT false,
  "needs_ai_retry" boolean NOT NULL DEFAULT false,
  PRIMARY KEY ("id")
);

-- Table: public.mind_logs  (rls_enabled=True, rows≈51)
CREATE TABLE "public"."mind_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "person_id" uuid,
  "mood_score" integer NOT NULL,
  "mood_emoji" text,
  "activities" jsonb DEFAULT '[]'::jsonb,
  "note" text,
  "log_date" date DEFAULT CURRENT_DATE,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.organizations  (rls_enabled=True, rows≈1)
-- Top-level tenant/guild structure for multi-tenant data isolation.
CREATE TABLE "public"."organizations" (
  "id" uuid NOT NULL,
  "name" text NOT NULL,
  "domain" text,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "tenant_id" text,
  PRIMARY KEY ("id")
);

-- Table: public.oxygen_saturation_logs  (rls_enabled=True, rows≈1807)
CREATE TABLE "public"."oxygen_saturation_logs" (
  "id" bigint NOT NULL DEFAULT nextval('oxygen_saturation_logs_id_seq'::regclass),
  "person_id" text,
  "saturation" real NOT NULL,
  "timestamp" bigint NOT NULL,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.person_widgets  (rls_enabled=True, rows≈14)
-- How the Hunter has customized their dashboard radar/HUD.
CREATE TABLE "public"."person_widgets" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "person_widget_id" integer,
  "person_id" uuid,
  "widget_name" text NOT NULL,
  "widget_type" text NOT NULL,
  "configuration" text DEFAULT '{}'::text,
  "display_order" integer DEFAULT 0,
  "is_active" boolean DEFAULT true,
  "role" text DEFAULT 'admin'::text,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.persons  (rls_enabled=True, rows≈6)
-- The main User identity table. Stores core demographics and link with other table by and for seperating the identity
CREATE TABLE "public"."persons" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "first_name" text,
  "last_name" text,
  "date_of_birth" date,
  "gender" text,
  "phone_number" text,
  "profile_image_url" text,
  "relationship" text DEFAULT 'none'::text,
  "affection" integer DEFAULT 0,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "cover_image_url" text,
  PRIMARY KEY ("id")
);

-- Table: public.portfolio_snapshots  (rls_enabled=True, rows≈427)
CREATE TABLE "public"."portfolio_snapshots" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "person_id" uuid,
  "total_net_worth" real NOT NULL DEFAULT 0.0,
  "ath_at_time" real NOT NULL DEFAULT 0.0,
  "timestamp" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.profiles  (rls_enabled=True, rows≈6)
-- Hunter extended profile data (bio, location, social links).
CREATE TABLE "public"."profiles" (
  "id" uuid NOT NULL,
  "profile_id" text,
  "person_id" uuid,
  "bio" text,
  "occupation" text,
  "education_level" text,
  "location" text,
  "website_url" text,
  "linkedin_url" text,
  "github_url" text,
  "timezone" text,
  "preferred_language" text,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "tenant_id" text,
  "cover_image_url" text,
  PRIMARY KEY ("id")
);

-- Table: public.project_metrics  (rls_enabled=True, rows≈9)
CREATE TABLE "public"."project_metrics" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "metric_id" text,
  "person_id" uuid,
  "date" date NOT NULL,
  "tasks_completed" integer DEFAULT 0,
  "projects_completed" integer DEFAULT 0,
  "focus_minutes" integer DEFAULT 0,
  "quest_points" double precision DEFAULT 0.0,
  "updated_at" timestamp with time zone DEFAULT now(),
  "category" text DEFAULT 'General'::text,
  PRIMARY KEY ("id")
);

-- Table: public.project_notes  (rls_enabled=True, rows≈19)
CREATE TABLE "public"."project_notes" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "note_id" text,
  "person_id" uuid,
  "title" text NOT NULL,
  "content" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "project_id" uuid,
  "category" text DEFAULT 'projects'::text,
  "mood" text,
  PRIMARY KEY ("id")
);

-- Table: public.projects  (rls_enabled=True, rows≈21)
-- Active missions or long-term operational tasks the Hunter is undertaking.
CREATE TABLE "public"."projects" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "project_id" text,
  "person_id" uuid,
  "name" text NOT NULL,
  "description" text,
  "category" text,
  "color" text,
  "status" integer DEFAULT 0,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "ssh_host_id" text,
  "remote_path" text,
  "ai_model" text,
  PRIMARY KEY ("id")
);

-- Table: public.quests  (rls_enabled=True, rows≈0)
-- Stores player trials, missions, and achievements across Health, Finance, Social, and Projects. The System uses this table to track Hunter progression and issue rewards.
CREATE TABLE "public"."quests" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "title" text NOT NULL,
  "description" text,
  "type" text DEFAULT 'daily'::text,
  "target_value" real DEFAULT 0.0,
  "current_value" real DEFAULT 0.0,
  "category" text DEFAULT 'health'::text,
  "reward_exp" integer DEFAULT 10,
  "is_completed" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now(),
  "image_url" text,
  "penalty_score" integer DEFAULT 0,
  "person_id" uuid,
  PRIMARY KEY ("id")
);

-- Table: public.quotes  (rls_enabled=True, rows≈0)
-- Daily motivational prompts loaded into the System HUD.
CREATE TABLE "public"."quotes" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "content" text NOT NULL,
  "author" text,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT now(),
  "person_id" uuid,
  PRIMARY KEY ("id")
);

-- Table: public.scores  (rls_enabled=True, rows≈4)
-- The Hunter's core System Attributes (STR, AGI, INT equivalents).
CREATE TABLE "public"."scores" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "score_id" text,
  "person_id" uuid,
  "health_global_score" real DEFAULT 0.0,
  "social_global_score" real DEFAULT 0.0,
  "financial_global_score" real DEFAULT 0.0,
  "career_global_score" real DEFAULT 0.0,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "penalty_score" real DEFAULT 0.0,
  PRIMARY KEY ("id")
);

-- Table: public.screen_time_settings  (rls_enabled=True, rows≈1)
CREATE TABLE "public"."screen_time_settings" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "person_id" uuid,
  "app_tokens" text[] DEFAULT '{}'::text[],
  "category_tokens" text[] DEFAULT '{}'::text[],
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.sessions  (rls_enabled=True, rows≈759)
-- Active device sessions and connection tokens for the System UI.
CREATE TABLE "public"."sessions" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "local_id" text,
  "jwt" text NOT NULL,
  "username" text,
  "created_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.skills  (rls_enabled=True, rows≈0)
CREATE TABLE "public"."skills" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "skill_id" text,
  "person_id" uuid,
  "skill_name" text NOT NULL,
  "skill_category" text,
  "proficiency_level" text DEFAULT 'beginner'::text,
  "years_of_experience" integer DEFAULT 0,
  "description" text,
  "is_featured" boolean DEFAULT false,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.sleep_logs  (rls_enabled=True, rows≈6)
-- Detailed session tracking for Hunter recovery periods.
CREATE TABLE "public"."sleep_logs" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "log_id" text,
  "person_id" uuid,
  "start_time" timestamp with time zone NOT NULL,
  "end_time" timestamp with time zone,
  "quality" integer DEFAULT 3,
  "source" text,
  PRIMARY KEY ("id")
);

-- Table: public.social_metrics  (rls_enabled=True, rows≈3)
CREATE TABLE "public"."social_metrics" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "tenant_id" uuid,
  "metric_id" text,
  "person_id" uuid,
  "date" date NOT NULL,
  "contacts_count" integer DEFAULT 0,
  "total_affection" integer DEFAULT 0,
  "quest_points" double precision DEFAULT 0.0,
  "updated_at" timestamp with time zone DEFAULT now(),
  "category" text DEFAULT 'General'::text,
  PRIMARY KEY ("id")
);

-- Table: public.subscriptions  (rls_enabled=True, rows≈3)
-- Finance module: recurring subscriptions (synced with local Drift).
CREATE TABLE "public"."subscriptions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "person_id" uuid,
  "name" text NOT NULL,
  "amount" numeric NOT NULL DEFAULT 0,
  "billing_day" integer NOT NULL,
  "category" text,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp with time zone DEFAULT now(),
  "billing_cycle" text NOT NULL DEFAULT 'monthly'::text,
  PRIMARY KEY ("id")
);

-- Table: public.themes  (rls_enabled=True, rows≈64)
-- System interface overlays and using json and store in local
CREATE TABLE "public"."themes" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "theme_id" text,
  "name" text NOT NULL,
  "alias" text NOT NULL,
  "json_content" text NOT NULL,
  "author" text NOT NULL,
  "added_date" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id")
);

-- Table: public.themes_config  (rls_enabled=True, rows≈2)
CREATE TABLE "public"."themes_config" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "theme_id" text,
  "theme_name" text NOT NULL,
  "theme_path" text NOT NULL,
  PRIMARY KEY ("id")
);

-- Table: public.transactions  (rls_enabled=True, rows≈8)
-- Ledger of gold gained (Loot/Income) and gold spent (Shop/Expense).
CREATE TABLE "public"."transactions" (
  "id" uuid NOT NULL,
  "tenant_id" uuid,
  "transaction_id" text,
  "person_id" uuid,
  "category" text NOT NULL,
  "type" text NOT NULL,
  "amount" real NOT NULL,
  "description" text,
  "transaction_date" timestamp with time zone DEFAULT now(),
  "created_at" timestamp with time zone DEFAULT now(),
  "project_id" uuid,
  PRIMARY KEY ("id")
);

-- Table: public.user_accounts  (rls_enabled=True, rows≈7)
-- System authentication and access control details for the Hunter.
CREATE TABLE "public"."user_accounts" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "person_id" text,
  "username" text,
  "password_hash" text,
  "primary_email_id" integer,
  "role" text DEFAULT 'user'::text,
  "is_locked" integer DEFAULT 0,
  "failed_login_attempts" integer DEFAULT 0,
  "last_login_at" text,
  "password_changed_at" text,
  "tenant_id" text,
  "created_at" timestamp with time zone,
  "updated_at" timestamp with time zone,
  PRIMARY KEY ("id")
);

-- Table: public.user_passkeys  (rls_enabled=False, rows≈13)
CREATE TABLE "public"."user_passkeys" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid,
  "credential_id" text NOT NULL,
  "public_key" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now(),
  "email" text NOT NULL,
  PRIMARY KEY ("id")
);

-- Table: public.water_logs  (rls_enabled=False, rows≈24)
CREATE TABLE "public"."water_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "health_metric_id" uuid,
  "tenant_id" uuid,
  "person_id" uuid,
  "amount" integer DEFAULT 250,
  "timestamp" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: public.webauthn_challenges  (rls_enabled=False, rows≈1)
CREATE TABLE "public"."webauthn_challenges" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "challenge" text NOT NULL,
  "email" text NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '00:05:00'::interval),
  "created_at" timestamp with time zone DEFAULT now(),
  "session_data" jsonb,
  PRIMARY KEY ("id")
);

-- Table: public.weight_logs  (rls_enabled=False, rows≈8)
CREATE TABLE "public"."weight_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "health_metric_id" uuid,
  "tenant_id" uuid,
  "person_id" uuid,
  "weight_kg" double precision NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: storage.buckets  (rls_enabled=True, rows≈0)
CREATE TABLE "storage"."buckets" (
  "id" text NOT NULL,
  "name" text NOT NULL,
  "owner" uuid,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "public" boolean DEFAULT false,
  "avif_autodetection" boolean DEFAULT false,
  "file_size_limit" bigint,
  "allowed_mime_types" text[],
  "owner_id" text,
  "type" storage.buckettype NOT NULL DEFAULT 'STANDARD'::storage.buckettype,
  PRIMARY KEY ("id")
);

-- Table: storage.buckets_analytics  (rls_enabled=True, rows≈0)
CREATE TABLE "storage"."buckets_analytics" (
  "name" text NOT NULL,
  "type" storage.buckettype NOT NULL DEFAULT 'ANALYTICS'::storage.buckettype,
  "format" text NOT NULL DEFAULT 'ICEBERG'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "deleted_at" timestamp with time zone,
  PRIMARY KEY ("id")
);

-- Table: storage.buckets_vectors  (rls_enabled=True, rows≈0)
CREATE TABLE "storage"."buckets_vectors" (
  "id" text NOT NULL,
  "type" storage.buckettype NOT NULL DEFAULT 'VECTOR'::storage.buckettype,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: storage.migrations  (rls_enabled=True, rows≈59)
CREATE TABLE "storage"."migrations" (
  "id" integer NOT NULL,
  "name" character varying NOT NULL,
  "hash" character varying NOT NULL,
  "executed_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

-- Table: storage.objects  (rls_enabled=True, rows≈0)
CREATE TABLE "storage"."objects" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "bucket_id" text,
  "name" text,
  "owner" uuid,
  "created_at" timestamp with time zone DEFAULT now(),
  "updated_at" timestamp with time zone DEFAULT now(),
  "last_accessed_at" timestamp with time zone DEFAULT now(),
  "metadata" jsonb,
  "path_tokens" text[] DEFAULT string_to_array(name, '/'::text),
  "version" text,
  "owner_id" text,
  "user_metadata" jsonb,
  PRIMARY KEY ("id")
);

-- Table: storage.s3_multipart_uploads  (rls_enabled=True, rows≈0)
CREATE TABLE "storage"."s3_multipart_uploads" (
  "id" text NOT NULL,
  "in_progress_size" bigint NOT NULL DEFAULT 0,
  "upload_signature" text NOT NULL,
  "bucket_id" text NOT NULL,
  "key" text NOT NULL,
  "version" text NOT NULL,
  "owner_id" text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "user_metadata" jsonb,
  "metadata" jsonb,
  PRIMARY KEY ("id")
);

-- Table: storage.s3_multipart_uploads_parts  (rls_enabled=True, rows≈0)
CREATE TABLE "storage"."s3_multipart_uploads_parts" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "upload_id" text NOT NULL,
  "size" bigint NOT NULL DEFAULT 0,
  "part_number" integer NOT NULL,
  "bucket_id" text NOT NULL,
  "key" text NOT NULL,
  "etag" text NOT NULL,
  "owner_id" text,
  "version" text NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Table: storage.vector_indexes  (rls_enabled=True, rows≈0)
CREATE TABLE "storage"."vector_indexes" (
  "id" text NOT NULL DEFAULT gen_random_uuid(),
  "name" text NOT NULL,
  "bucket_id" text NOT NULL,
  "data_type" text NOT NULL,
  "dimension" integer NOT NULL,
  "distance_metric" text NOT NULL,
  "metadata_configuration" jsonb,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- Foreign keys (deduplicated by constraint name)
ALTER TABLE ONLY "auth"."saml_relay_states"
  ADD CONSTRAINT "saml_relay_states_flow_state_id_fkey" FOREIGN KEY ("flow_state_id") REFERENCES "auth"."flow_state"("id");
ALTER TABLE ONLY "auth"."identities"
  ADD CONSTRAINT "identities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."mfa_amr_claims"
  ADD CONSTRAINT "mfa_amr_claims_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id");
ALTER TABLE ONLY "auth"."mfa_challenges"
  ADD CONSTRAINT "mfa_challenges_auth_factor_id_fkey" FOREIGN KEY ("factor_id") REFERENCES "auth"."mfa_factors"("id");
ALTER TABLE ONLY "auth"."mfa_factors"
  ADD CONSTRAINT "mfa_factors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."oauth_authorizations"
  ADD CONSTRAINT "oauth_authorizations_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id");
ALTER TABLE ONLY "auth"."oauth_authorizations"
  ADD CONSTRAINT "oauth_authorizations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."oauth_consents"
  ADD CONSTRAINT "oauth_consents_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id");
ALTER TABLE ONLY "auth"."sessions"
  ADD CONSTRAINT "sessions_oauth_client_id_fkey" FOREIGN KEY ("oauth_client_id") REFERENCES "auth"."oauth_clients"("id");
ALTER TABLE ONLY "auth"."oauth_consents"
  ADD CONSTRAINT "oauth_consents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."one_time_tokens"
  ADD CONSTRAINT "one_time_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."refresh_tokens"
  ADD CONSTRAINT "refresh_tokens_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id");
ALTER TABLE ONLY "auth"."saml_providers"
  ADD CONSTRAINT "saml_providers_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id");
ALTER TABLE ONLY "auth"."saml_relay_states"
  ADD CONSTRAINT "saml_relay_states_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id");
ALTER TABLE ONLY "auth"."sessions"
  ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."sso_domains"
  ADD CONSTRAINT "sso_domains_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id");
ALTER TABLE ONLY "public"."user_passkeys"
  ADD CONSTRAINT "user_passkeys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."heart_rate_logs"
  ADD CONSTRAINT "heart_rate_logs_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."screen_time_settings"
  ADD CONSTRAINT "screen_time_settings_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."webauthn_credentials"
  ADD CONSTRAINT "webauthn_credentials_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "auth"."webauthn_challenges"
  ADD CONSTRAINT "webauthn_challenges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");
ALTER TABLE ONLY "public"."ai_analysis"
  ADD CONSTRAINT "blog_posts_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."ai_analysis"
  ADD CONSTRAINT "blog_posts_author_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."assets"
  ADD CONSTRAINT "assets_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."assets"
  ADD CONSTRAINT "assets_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."custom_notifications"
  ADD CONSTRAINT "custom_notifications_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."custom_notifications"
  ADD CONSTRAINT "custom_notifications_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."days"
  ADD CONSTRAINT "days_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."detail_information"
  ADD CONSTRAINT "detail_information_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."detail_information"
  ADD CONSTRAINT "detail_information_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."email_addresses"
  ADD CONSTRAINT "email_addresses_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."email_addresses"
  ADD CONSTRAINT "email_addresses_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."exercise_logs"
  ADD CONSTRAINT "exercise_logs_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."exercise_logs"
  ADD CONSTRAINT "exercise_logs_health_metric_id_fkey" FOREIGN KEY ("health_metric_id") REFERENCES "public"."health_metrics"("id");
ALTER TABLE ONLY "public"."exercise_logs"
  ADD CONSTRAINT "exercise_logs_focus_session_id_fkey" FOREIGN KEY ("focus_session_id") REFERENCES "public"."focus_sessions"("id");
ALTER TABLE ONLY "public"."exercise_logs"
  ADD CONSTRAINT "exercise_logs_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."external_widgets"
  ADD CONSTRAINT "external_widgets_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."financial_accounts"
  ADD CONSTRAINT "financial_accounts_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."financial_accounts"
  ADD CONSTRAINT "financial_accounts_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."financial_metrics"
  ADD CONSTRAINT "financial_metrics_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."financial_metrics"
  ADD CONSTRAINT "financial_metrics_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."focus_sessions"
  ADD CONSTRAINT "focus_sessions_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."focus_sessions"
  ADD CONSTRAINT "focus_sessions_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id");
ALTER TABLE ONLY "public"."focus_sessions"
  ADD CONSTRAINT "focus_sessions_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."focus_sessions"
  ADD CONSTRAINT "focus_sessions_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."goals"("id");
ALTER TABLE ONLY "public"."goals"
  ADD CONSTRAINT "goals_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."goals"
  ADD CONSTRAINT "goals_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."habits"
  ADD CONSTRAINT "habits_goal_id_fkey" FOREIGN KEY ("goal_id") REFERENCES "public"."goals"("id");
ALTER TABLE ONLY "public"."goals"
  ADD CONSTRAINT "goals_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id");
ALTER TABLE ONLY "public"."habits"
  ADD CONSTRAINT "habits_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."habits"
  ADD CONSTRAINT "habits_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."weight_logs"
  ADD CONSTRAINT "weight_logs_health_metric_id_fkey" FOREIGN KEY ("health_metric_id") REFERENCES "public"."health_metrics"("id");
ALTER TABLE ONLY "public"."water_logs"
  ADD CONSTRAINT "water_logs_health_metric_id_fkey" FOREIGN KEY ("health_metric_id") REFERENCES "public"."health_metrics"("id");
ALTER TABLE ONLY "public"."health_metrics"
  ADD CONSTRAINT "health_metrics_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."hourly_activity_log"
  ADD CONSTRAINT "hourly_activity_log_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."internal_widgets"
  ADD CONSTRAINT "internal_widgets_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."meals"
  ADD CONSTRAINT "meals_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."meals"
  ADD CONSTRAINT "meals_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."mind_logs"
  ADD CONSTRAINT "mind_logs_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."sleep_logs"
  ADD CONSTRAINT "sleep_logs_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."project_notes"
  ADD CONSTRAINT "project_notes_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."persons"
  ADD CONSTRAINT "persons_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."projects"
  ADD CONSTRAINT "projects_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."skills"
  ADD CONSTRAINT "skills_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."transactions"
  ADD CONSTRAINT "transactions_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."person_widgets"
  ADD CONSTRAINT "person_widgets_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."scores"
  ADD CONSTRAINT "scores_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."themes"
  ADD CONSTRAINT "themes_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."themes_config"
  ADD CONSTRAINT "themes_config_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."quotes"
  ADD CONSTRAINT "quotes_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."quests"
  ADD CONSTRAINT "quests_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."sessions"
  ADD CONSTRAINT "sessions_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."portfolio_snapshots"
  ADD CONSTRAINT "portfolio_snapshots_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."project_metrics"
  ADD CONSTRAINT "project_metrics_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."social_metrics"
  ADD CONSTRAINT "social_metrics_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."organizations"("id");
ALTER TABLE ONLY "public"."person_widgets"
  ADD CONSTRAINT "person_widgets_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."sleep_logs"
  ADD CONSTRAINT "sleep_logs_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."subscriptions"
  ADD CONSTRAINT "subscriptions_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."weight_logs"
  ADD CONSTRAINT "weight_logs_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."water_logs"
  ADD CONSTRAINT "water_logs_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."social_metrics"
  ADD CONSTRAINT "social_metrics_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."project_metrics"
  ADD CONSTRAINT "project_metrics_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."portfolio_snapshots"
  ADD CONSTRAINT "portfolio_snapshots_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."scores"
  ADD CONSTRAINT "scores_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."transactions"
  ADD CONSTRAINT "transactions_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."skills"
  ADD CONSTRAINT "skills_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."projects"
  ADD CONSTRAINT "projects_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."profiles"
  ADD CONSTRAINT "profiles_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."project_notes"
  ADD CONSTRAINT "project_notes_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id");
ALTER TABLE ONLY "public"."project_notes"
  ADD CONSTRAINT "project_notes_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id");
ALTER TABLE ONLY "public"."transactions"
  ADD CONSTRAINT "transactions_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id");
ALTER TABLE ONLY "storage"."objects"
  ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");
ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
  ADD CONSTRAINT "s3_multipart_uploads_parts_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");
ALTER TABLE ONLY "storage"."s3_multipart_uploads"
  ADD CONSTRAINT "s3_multipart_uploads_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");
ALTER TABLE ONLY "storage"."vector_indexes"
  ADD CONSTRAINT "vector_indexes_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets_vectors"("id");
ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
  ADD CONSTRAINT "s3_multipart_uploads_parts_upload_id_fkey" FOREIGN KEY ("upload_id") REFERENCES "storage"."s3_multipart_uploads"("id");

-- Column comments (where provided by catalog)
COMMENT ON COLUMN "auth"."identities"."email" IS 'Auth: Email is a generated column that references the optional email property in the identity_data';
COMMENT ON COLUMN "auth"."mfa_factors"."last_webauthn_challenge_data" IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';
COMMENT ON COLUMN "auth"."sessions"."not_after" IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';
COMMENT ON COLUMN "auth"."sessions"."refresh_token_hmac_key" IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';
COMMENT ON COLUMN "auth"."sessions"."refresh_token_counter" IS 'Holds the ID (counter) of the last issued refresh token.';
COMMENT ON COLUMN "auth"."sso_providers"."resource_id" IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';
COMMENT ON COLUMN "auth"."users"."is_sso_user" IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';
COMMENT ON COLUMN "public"."ai_analysis"."person_id" IS 'The Hunter who this analysis belongs to.';
COMMENT ON COLUMN "public"."ai_analysis"."detailed_analysis" IS 'The full, unstructured or markdown output from the AI.';
COMMENT ON COLUMN "public"."ai_analysis"."ai_model" IS 'The specific AI model version used to generate this report.';
COMMENT ON COLUMN "public"."assets"."current_estimated_value" IS 'Market value of the asset.';
COMMENT ON COLUMN "public"."detail_information"."cover_image_url" IS 'URL for the cover image associated with the address/portfolio';
COMMENT ON COLUMN "public"."exercise_logs"."mood_score" IS 'Optional 1–5 mood after activity (matches finance savings mood scale).';
COMMENT ON COLUMN "public"."financial_accounts"."balance" IS 'Current amount of gold/currency available.';
COMMENT ON COLUMN "public"."focus_sessions"."duration_seconds" IS 'Total time spent grinding/focusing.';
COMMENT ON COLUMN "public"."goals"."progress_percentage" IS '0 to 100 completion rate of the goal.';
COMMENT ON COLUMN "public"."habits"."frequency" IS 'How often the habit triggers (daily, weekly).';
COMMENT ON COLUMN "public"."organizations"."name" IS 'Name of the guild or organization.';
COMMENT ON COLUMN "public"."persons"."relationship" IS 'Current bond status: friend, dating, family, etc.';
COMMENT ON COLUMN "public"."persons"."affection" IS 'System Affection/Bond level. Ranges determine relationship status.';
COMMENT ON COLUMN "public"."persons"."cover_image_url" IS 'URL for the user profile cover image';
COMMENT ON COLUMN "public"."profiles"."cover_image_url" IS 'URL for the user profile cover image (redundant/cached)';
COMMENT ON COLUMN "public"."projects"."status" IS '0 = Active, 1 = Completed/Archived.';
COMMENT ON COLUMN "public"."quests"."category" IS 'The skill tree this quest belongs to. Essential for routing EXP. Expected categories: "health", "finance", "social", "project", or "feat".';
COMMENT ON COLUMN "public"."quests"."reward_exp" IS 'XP granted to the corresponding category upon completion. Range usually: 10 (E Rank / Easy) to 50 (S Rank / High Difficulty).';
COMMENT ON COLUMN "public"."quests"."person_id" IS 'Refer to person id';
COMMENT ON COLUMN "public"."scores"."health_global_score" IS 'Overall Vitality/Health rank points.';
COMMENT ON COLUMN "public"."scores"."social_global_score" IS 'Overall Charisma/Bond rank points.';
COMMENT ON COLUMN "public"."scores"."financial_global_score" IS 'Overall Wealth/Resource rank points.';
COMMENT ON COLUMN "public"."scores"."career_global_score" IS 'Overall Intelligence/Career rank points.';
COMMENT ON COLUMN "public"."transactions"."type" IS 'Income or Expense classification.';
COMMENT ON COLUMN "public"."user_accounts"."role" IS 'System role (e.g., admin, user, hunter).';
COMMENT ON COLUMN "storage"."buckets"."owner" IS 'Field is deprecated, use owner_id instead';
COMMENT ON COLUMN "storage"."objects"."owner" IS 'Field is deprecated, use owner_id instead';
