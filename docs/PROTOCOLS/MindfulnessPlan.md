# Mindfulness (Zen) Ranking System Plan

This document outlines the integration of a gamified mindfulness ranking system as an **Internal Plugin** for Ice Shield. 

## 1. Concept
The system tracks "Mental Stillness" (Stoic Buddhism) via three key metrics:
- **Stillness Quotient (SQ)**: Ability to stay focused during meditation.
- **Stoic Shield**: Maintaining equanimity during stressful impulses.
- **Dopamine Fast**: Resisting quick-fix distractions.

## 2. Technical Architecture

### Data Layer
- **Schema Update**: Add `zen_global_score` to the `scores` table in PowerSync.
- **Session Logging**: Create a `mindfulness_logs` table to track individual practice sessions.
- **MindfulnessDAO**: A new DAO in `Database.dart` to manage Zen-related data.

### Scoring Integration
- **ScoreBlock**: The Zen score will be added as a **5th pillar** to the user's global level.
- **Reactive Updates**: The global level will dynamically update as the user logs Zen activities.

### UI Layer
- **Plugin Tile (`ZenWidget.dart`)**: A compact dashboard element for the home page.
- **Zen Hub (`ZenPage.dart`)**: A dedicated full-screen page for meditation timing and Stoic reflection logging.

## 3. Implementation Steps
1. **Database Migration**: Update schema and DAOs.
2. **Logic Integration**: Update `ScoreBlock` and `ScoreData`.
3. **UI Development**: Build the plugin tile and the Zen Hub page.
4. **Registration**: Add the "Zen" plugin to the internal widget registry.
