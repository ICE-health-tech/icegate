# Quest System Upgrade Report - March 13, 2026

## Objective
Enhance the Quest system to align with real-life activities and implement automated daily generation with multiple quest types (Daily and Secret).

## Implemented Changes

### 1. Database Schema Enhancements (`Database.dart`)
- **QuestsTable**:
    - Added `questType` column to identify specific real-life activities (e.g., 'walking', 'running', 'swimming', 'pushups').
    - Refined `type` column documentation to include 'daily', 'weekly', 'secret', and 'system'.
- **ProfilesTable**:
    - Added `lastQuestGeneratedAt` column to track when the last batch of daily quests was generated for a user, preventing multiple generations in a single day.
- **PersonManagementDAO**:
    - Added `updateLastQuestGeneratedAt` method to update the generation timestamp.
    - Added `deleteAllQuestsByPerson` (helper for potential future resets).

### 2. Quest Generation Logic (`QuestService.dart`)
- Created a new `QuestService` class to handle business logic for quests.
- **Daily Generation**: Checks if quests have been generated today. If not, it picks 2 random health-related quests from a real-life template pool.
- **Real-life Templates**:
    - **Morning Run**: 30 minutes.
    - **Walking Master**: 10,000 steps.
    - **Swimming Session**: 45 minutes.
    - **Pushup Challenge**: 50 pushups.
- **Secret Quests**: Implemented a 30% chance each day to generate a "Secret Quest" with high rewards (150 XP) and hidden descriptions.

### 3. Reactive Integration (`QuestBlock.dart` & `DataLayer.dart`)
- **QuestBlock**: Updated `init` to accept the full `AppDatabase`. It now triggers the `QuestService.generateDailyQuestsIfNeeded` during initialization.
- **DataLayer**: Updated the block initialization sequence to pass the database instance to `QuestBlock`.

## Real-life Mapping
- The `questType` field now allows the app to map specific incoming data (Health, Pedometer) to quest progress based on activity type.
- **Finance Integration**: Added a specific "Virtual Office Budget" quest template to help users manage recurring business expenses (e.g., Green Office at 650,000 VND).
- **Project Notes**: Seeded a permanent information note for "Văn phòng ảo" in the finance category for quick reference to pricing and service links.

## Next Steps
- Implement UI indicators to distinguish between "Daily" and "Secret" quests.
- Add specific data listeners for "Swimming" and "Pushups" (manual entry or AR-based detection).
