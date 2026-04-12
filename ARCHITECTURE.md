# ICE Gate: Architecture, Design, and Maintenance Plan

## 1. App Function & Purpose

**ICE Gate** is designed as a **Life Orchestration Engine (LOE)** and a **"Gateway to Hubs."**

Rather than being a traditional, siloed application, it acts as a central hub that aggregates, visualizes, and gamifies data from various aspects of a user's life.

The app acts as a gate and can connect to various hubs:
* **Health Hubs:** (e.g., Apple Health) for tracking physical metrics like steps walked, sleep, and heart rate.
* **Social Hubs:** (e.g., Facebook, Instagram, TikTok) for managing relationships, contacts, and social "quests."
* **Finance Hubs:** For planning and tracking net worth, savings, and investments.
* **Career/Project Hubs:** For task management, external SSH connections, AI agent orchestrations, and project completion.

The core gamification loop translates real-world metrics (steps walked, tasks completed, money saved) into **Quest Points (XP)** across these pillars, providing users with a holistic "Score Balance" to motivate self-improvement.

The score must intuitively represent and contain actionable information, keeping users updated on their daily progress. The ultimate goal is to help people visualize their life progress effortlessly.

---

## 2. UI Style

* **Visual Paradigm:** Flat design combined with Apple Dynamic Glass effects.
* **UX Strategy:** Maximize user convenience; ensure that the user can accomplish tasks and view data without needing to touch or navigate through too many screens.
* **Aesthetic Strategy:** The app utilizes a highly stylized, futuristic/cyberpunk aesthetic (e.g., "SeedBlue," "Neon," "Dark Mode" JSON themes) to reinforce the "Gateway" concept.

---

## 3. Design Plan & Architecture

The application follows a strict, domain-driven **Layered Architecture** to ensure scalability and separation of concerns.

### Layered Structure

1. **Data Layer (`lib/data_layer/`)**:
   * **Local-First:** Uses `drift` (SQLite) for offline-first data storage, ensuring privacy and speed.
   * **Cloud Sync:** Uses `powersync` and `supabase` to selectively sync data only when the user "enrolls" in a hub.
   * **Protocols:** Defines strict data models and protocols (e.g., `HealthMetricsData`, `ProjectProtocol`).

2. **Initial Layer (`lib/initial_layer/`)**:
   * Handles app bootstrap, dependency injection setup, theme initialization (`ThemeLayer`), and core data layer bindings (`DataLayer`).
   * Bootstraps foundational services before the UI is fully rendered.

3. **Security & Routing Layer (`lib/security_routing_layer/`)**:
   * Manages application routing state (via `go_router`).
   * Handles internal URL routing (`internal_route.dart`), deep linking, and enforcing security/auth checks before navigating to protected views.

4. **Localization (`lib/l10n/`)**:
   * Contains string resources and configurations for internationalization.

5. **Orchestration Layer (`lib/orchestration_layer/`)**:
   * **Reactive State:** Utilizes the `signals` package to manage state reactively. `ReactiveBlocks` (e.g., `FinanceBlock`, `ScoreBlock`, `LocaleBlock`) listen to database streams and expose simple properties for the UI to consume.
   * **Business Logic:** Contains the "Life Orchestration Engine" that calculates gamification points and orchestrates actions across different domain hubs.

6. **UI Layer (`lib/ui_layer/`)**:
   * **Stateless by Default:** UI components are mostly stateless, heavily relying on `Watch` from `signals_flutter` to automatically rebuild when the Orchestration Layer updates.
   * **Plugin/Widget System:** The Canvas dashboard is dynamic, allowing users to drop "Internal Widgets" (e.g., Health Department) and "External Widgets" (WebViews).

---

## 4. Maintenance Strategy & Future-Proofing

To prevent "AI Drift" and keep the codebase manageable over time, the following rules must be adhered to during maintenance and expansion:

### A. The Plugin Protocol (Adding New Features)
Do not build monolithic new features into the core UI. Instead, treat new features as **Plugins** or **Hub Adapters**.
1. **Define:** Create a new Protocol in `data_layer/`.
2. **Orchestrate:** Create a dedicated `ReactiveBlock` in `orchestration_layer/`.
3. **UI Integration:** Build the UI in `ui_layer/` and register it so it can be added to the user's Canvas or specific Department page.

### B. State Management Discipline (Signals)
* **Never mix UI and Business Logic.** The UI (`build` methods) should only read from `Signals` and trigger actions in `ReactiveBlocks`.
* Avoid `setState` where possible; rely on `signals` for granular, efficient rebuilds.

### C. Data Synchronization (Local vs. Cloud)
* Assume the user is offline by default. Always write to the local Drift database (`DAO`s).
* Let `PowerSync` handle the background synchronization to Supabase. Do not write direct API calls to Supabase for standard CRUD operations unless bypassing sync is explicitly required (e.g., Authentication).

### D. Coding Standards (AI Agents Rules)
* **Explanation:** When adding code, always provide comments explaining the logic.
* **File Size:** Separate long files into smaller, focused files to maintain readability.
* **Knowledge Base:** Always refer to the local directory `/Users/duylong/Code/AI_Knowledge` for global knowledge, implementation reports, and key insights. Flowcharts should be created before adding new complex functions.

### E. The AI-Driven Cycle & Manual Review
1. **AI Generation:** Use AI tools to quickly generate boilerplate, logic blocks, and UI structures.
2. **Deployment:** Rely on automated GitHub Actions and local scripts (like `delivery_cycle.sh` and `deploy_testflight.sh`) to push to Docker (Web) and TestFlight (iOS).
3. **Review Buffer:** Implement a strict cooling-off period where new AI-generated code is manually reviewed, tested on-device, and refactored by a human developer before the next major sprint. This ensures architectural integrity remains high.
