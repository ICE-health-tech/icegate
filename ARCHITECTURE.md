# System prompts

# Workspace prompts



# ICE Gate: Architecture, Design, and Maintenance Plan

  

## 1. App Function & Purpose

**ICE Gate** is designed as a **Life Orchestration Engine (LOE)** and a **"Gateway to Hubs."**

Rather than being a traditional, siloed application, it acts as a central hub that aggregates, visualizes, and gamifies data from various aspects of a user's life.

The app as gate and can connect to hub. like social hub like tiktok and facebook
health hub to sensor, project hub to ssh and AI agent and finance hub for planing the finance

  

It connects to:

* **Health Hubs:** (e.g., Apple Health) for step tracking, sleep, and heart rate.

* **Social Hubs:** (e.g., Facebook, Instagram, TikTok) for managing relationships, contacts, and social "quests."

* **Finance Hubs:** For tracking net worth, savings, and investments.

* **Career/Project Hubs:** For task management and project completion.

  

The core gamification loop translates real-world metrics (steps walked, tasks completed, money saved) into **Quest Points (XP)** across these four pillars, providing users with a holistic "Score Balance" to motivate self-improvement..

The score must represent and contain information for easy using. Like show today point.

The meaning: Help people and users know the progress

  

---
## UI syle
+ Using flat design with apple dynamic glass for UI
+ Make every convenient for user using it without touch many thing screen
+ 
  

## 2. Design Plan & Architecture

  

The application follows a strict, domain-driven **Layered Architecture** to ensure scalability and separation of concerns.

  

### Layered Structure

1. **Data Layer (`data_layer/`)**:

* **Local-First:** Uses `drift` (SQLite) for offline-first data storage, ensuring privacy and speed.

* **Cloud Sync:** Uses `powersync` and `supabase` to selectively sync data only when the user "enrolls" in a hub.

* **Protocols:** Defines strict data models (e.g., `HealthMetricsData`, `ProjectProtocol`).

2. **Initial Layer (`initial_layer/`)**:

* Handles app bootstrap, routing configuration (`go_router`), theme setup, and core services (e.g., `CustomAuthService`, `SecureStorageService`).

3. **Orchestration Layer (`orchestration_layer/`)**:

* **Reactive State:** Utilizes the `signals` package to manage state reactively. `ReactiveBlocks` (e.g., `HealthBlock`, `AuthBlock`) listen to database streams and expose simple properties for the UI to consume.

* **Business Logic:** Contains the "Life Orchestration Engine" (`ScoreBlock`) that calculates gamification points.

4. **UI Layer (`ui_layer/`)**:

* **Stateless by Default:** UI components are mostly stateless, heavily relying on `Watch` from `signals_flutter` to automatically rebuild when the Orchestration Layer updates.

* **Plugin/Widget System:** The Canvas dashboard is dynamic, allowing users to drag and drop "Internal Widgets" (e.g., Health Department) and "External Widgets" (WebViews).

  

### Aesthetic Strategy

* **Theme:** The app utilizes a highly stylized, futuristic/cyberpunk aesthetic (e.g., "SeedBlue," "Neon," "Dark Mode" JSON themes) to reinforce the "Gateway" concept.

  

---

  

## 3. Maintenance Strategy & Future-Proofing

  

To prevent "AI Drift" and keep the codebase manageable over time, the following rules must be adhered to during maintenance and expansion:

  

### A. The Plugin Protocol (Adding New Features)

Do not build monolithic new features into the core UI. Instead, treat new features as **Plugins** or **Hub Adapters**.

1. **Define:** Create a new Protocol in `data_layer/`.

2. **Orchestrate:** Create a dedicated `ReactiveBlock` in `orchestration_layer/`.

3. **UI Integration:** Build the UI in `ui_layer/widget_page/PluginList/` and register it so it can be added to the user's Canvas or specific Department page (like the Social "Journal" tab).

  

### B. State Management Discipline (Signals)

* **Never mix UI and Business Logic.** The UI (`build` methods) should only read from `Signals` and trigger actions in `ReactiveBlocks`.

* Avoid `setState` where possible; rely on `signals` for granular, efficient rebuilds.

  

### C. Data Synchronization (Local vs. Cloud)

* Assume the user is offline by default. Always write to the local Drift database (`DAO`s).

* Let `PowerSync` handle the background synchronization to Supabase. Do not write direct API calls to Supabase for standard CRUD operations unless bypassing sync is explicitly required (e.g., Authentication).

  

### D. The AI-Driven Cycle & Manual Review

As outlined in the development workflow:

1. **AI Generation:** Use Gemini to quickly generate boilerplate, logic blocks, and UI structures.

2. **Deployment:** Rely on automated GitHub Actions to push to Docker (Web) and TestFlight (iOS).

3. **The 1-Week Buffer:** Implement a strict 1-week cooling-off period where new AI-generated code is manually reviewed, tested on device, and refactored by a human developer before the next major AI-driven sprint. This ensures architectural integrity remains high.











# Entry



