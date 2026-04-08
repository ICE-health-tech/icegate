# Ice Shield Database Schema

This document outlines the database structure for the Ice Shield application. The system uses a multi-layered database architecture:
- **Local (Drift/SQLite):** Fast local storage with reactive streams.
- **Sync (PowerSync):** Synchronizes local SQLite data with Supabase.
- **Remote (Supabase/PostgreSQL):** Persistent cloud storage and authentication.

---

## 🔐 Core Identity & User Management

### `persons`
Core person entities (the user as "me" and all contacts/social connections).
- `id` (UUID): Primary key for sync.
- `person_id` (Int): Unique business logic ID.
- `first_name`, `last_name` (Text): Name information.
- `date_of_birth` (DateTime): Birth date.
- `gender` (Text): Demographic info.
- `phone_number`, `profile_image_url` (Text): Contact & Visuals.
- `relationship` (Text): 'me', 'friend', 'dating', 'family', etc.
- `affection` (Int): Relationship strength score.
- `is_active` (Bool): Status flag.
- `created_at`, `updated_at` (DateTime): Auditing.

### `user_accounts`
Authentication and account-specific settings.
- `username` (Text): Unique login name.
- `password_hash` (Text): Secure password storage.
- `role` (Enum): 'user', 'admin', 'viewer'.
- `is_locked` (Bool): Account security status.
- `last_login_at` (DateTime): Activity tracking.

### `email_addresses`
Email contact points for persons.
- `email_address` (Text): The address string.
- `email_type` (Text): 'personal', 'work', etc.
- `is_primary` (Bool): Primary contact flag.
- `status` (Enum): 'pending', 'verified', 'bounced', etc.

### `profiles` & `detail_information`
Extended personal and professional information.
- `bio`, `occupation`, `education_level` (Text).
- `location`, `country` (Text).
- `github_url`, `linkedin_url`, `website_url` (Text).

---

## 🏃 Health & Wellness

### `health_metrics`
Daily snapshot of health stats.
- `date` (DateTime): The calendar day.
- `steps` (Int): Total step count.
- `heart_rate` (Int): Average/Latest BPM.
- `sleep_hours` (Real): Total sleep duration.
- `water_glasses` (Int): Hydration level.
- `exercise_minutes` (Int): Active workout time.
- `focus_minutes` (Int): High-productivity time.
- `weight_kg` (Real): Body weight.
- `calories_consumed` / `calories_burned` (Int).

### `health_logs` (Sub-tables)
- `water_logs`: Individual hydration events.
- `sleep_logs`: Sleep sessions (start/end times).
- `exercise_logs`: Individual workout sessions (type/intensity).

### `meals` & `days`
Detailed nutrition tracking.
- `meals`: Table for logged food items (fat, carbs, protein, calories).
- `days`: Summary table for daily totals (calories_out, weight).

---

## 🚀 Projects & Productivity

### `projects`
Organizational buckets for work and notes.
- `name`, `description` (Text).
- `category` (Text): Project grouping.
- `color` (Text): UI accent color.
- `status` (Int): Progress status.
- `ssh_host_id` (Text): Link to a specific SSH host.
- `remote_path` (Text): Path on the remote server.
- `ai_model` (Text): The AI agent model assigned to the project (e.g., 'gemini', 'opencode').

### `project_notes`
Note content associated with projects or general.
- `title` (Text).
- `content` (Text): Note body (often JSON for rich text).
- `project_id` (Int): Optional link to a project.

### `focus_sessions`
Pomodoro or deep work sessions.
- `start_time` / `end_time` (DateTime).
- `duration_seconds` (Int).
- `status` (Text): 'completed', 'interrupted'.
- `task_id` (Int): Link to a specific goal/habit.

---

## 💰 Financial Tracking

### `financial_accounts`
Bank accounts, wallets, or credit cards.
- `account_name` (Text).
- `account_type` (Text): 'checking', 'savings', 'credit'.
- `balance` (Real): Current funds.
- `currency` (Enum): 'USD', 'VND', etc.
- `is_primary` (Bool): Default account flag.

### `assets`
Physical or digital property/investments.
- `asset_name`, `asset_category` (Text).
- `purchase_price`, `current_estimated_value` (Real).

### `transactions`
Income and expense ledger.
- `amount` (Real).
- `category` / `type` (Text).
- `transaction_date` (DateTime).

---

## 🎮 Gamification & Widgets

### `scores`
Global scores across the four life dimensions.
- `health_global_score`
- `social_global_score`
- `financial_global_score`
- `career_global_score`

### `goals` & `habits`
Aspirational targets and repeated actions.
- `goals`: Long-term targets with categories and priority.
- `habits`: Recurring tasks with frequency and target counts.

### `quests`
Dynamic tasks and challenges.
- `reward_exp` (Int).
- `target_value` / `current_value` (Real).

### `internal_widgets` & `external_widgets`
Configurable UI elements for the Home Canvas.
- `name`, `url`, `image_url` (Text).
- `alias` (Text): Unique identifier for the widget system.

---

## ⚙️ System & Config

### `sessions`
Local authentication session state.
- `jwt` (Text): Authentication token.
- `username` (Text).

### `themes_config` & `themes`
UI customization and theming.
- `json_content` (Text): The theme definition.
- `theme_path` (Text).

### `custom_notifications`
Scheduled local alerts.
- `title`, `content` (Text).
- `scheduled_time` (DateTime).
- `repeat_frequency` (Text).

### `quotes`
Motivational texts shown throughout the app.
- `content`, `author` (Text).
