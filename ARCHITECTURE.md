# ICE Gate Architecture

ICE Gate is a high-performance, offline-first personal management system built with Flutter. It utilizes a multi-layered architecture designed for reactivity, scalability, and robust data synchronization.

## 🏗 Architectural Layers

The project is organized into five primary layers:

### 1. Data Layer (`lib/data_layer`)
The foundation of the application, responsible for data persistence, external communication, and domain models.
- **DataSources**: Contains local database definitions (Drift/SQLite) and cloud connectors (PowerSync + Supabase).
- **DomainData**: Core business models and entities.
- **Protocol**: Interfaces and adapters for standardized communication between services.
- **Services**: Low-level services for specialized tasks (e.g., Auth, Storage).

### 2. Orchestration Layer (`lib/orchestration_layer`)
Handles the application's "brain" logic and reactive state management.
- **ReactiveBlocks**: The primary state containers. They use the **Signals** pattern (`signals_flutter`) for fine-grained reactivity and are distributed via **Provider**.
- **Action**: Encapsulates complex, multi-step business processes that span multiple blocks or services.

### 3. Initial Layer (`lib/initial_layer`)
Manages the application's lifecycle and bootstrapping.
- **DataLayer.dart**: A "God Widget" that initializes all core services (Database, Supabase, Notifications, Audio) and provides them to the widget tree.
- **ThemeLayer / ThemeAdapter**: Manages dynamic theme switching and Material Design mapping.
- **CoreLogics**: Essential startup logic like Biometric Auth, Passkey support, and Secure Storage initialization.

### 4. Security & Routing Layer (`lib/security_routing_layer`)
Manages access control and navigation flow.
- **Routing**: Implementation of **GoRouter** with centralized route definitions (`InternalRoute.dart`).
- **Auth Guards**: Logic for redirecting users based on authentication status and handling deep links.



MainButton refer to 
 page-level to the global 
MainShell
 to ensure consistent UI across the application.

### 5. UI Layer (`lib/ui_layer`)
The presentation layer, organized by feature/domain.
- **Feature Folders**: (e.g., `health_page`, `finance_page`, `social_page`) contains pages and widgets specific to that domain.
- **ReusableWidget**: Atomic and molecular UI components used across the app.
- **Canvas Page**: Specialized UI for the dynamic, grid-based widget system.

## 🔄 Core Technologies & Patterns

- **State Management**: **Signals + Provider**. Signals provide fine-grained reactivity (minimizing rebuilds), while Provider is used for Dependency Injection.
- **Database**: **Drift (SQLite)** for local persistence with a **DAO (Data Access Object)** pattern.
- **Synchronization**: **PowerSync** for seamless, offline-first synchronization with **Supabase**.
- **Navigation**: **GoRouter** with ShellRoute for persistent navigation elements (MainShell).
- **Reactivity**: Heavy use of the `Watch` and `effect` patterns to keep the UI and data layers in sync automatically.

## 🚀 Initialization Flow

1. `main()` calls `runApp` with `DataLayer`.
2. `DataLayer` initializes async services (Supabase, PowerSync, Notifications).
3. `DataLayer` instantiates all `ReactiveBlock`s.
4. `DataLayer` provides services and blocks to the tree via `MultiProvider`.
5. `ThemeLayer` and `Adapter` handle final UI-related setups (Theme loading, default widget checks).
6. `MaterialApp.router` is built, using `GoRouter` for navigation.

## 🛠 Design Principles

- **Offline-First**: All user data is stored locally first and synced in the background.
- **Reactive Integrity**: The UI always reflects the current state of the `ReactiveBlocks`.
- **Surgical Updates**: Using Signals ensures that only the specific widgets needing an update are rebuilt.
- **Layered Decoupling**: UI components do not talk directly to the database; they interact via `ReactiveBlock`s or `Action`s.



