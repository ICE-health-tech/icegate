# ICE Gate Database Schema Documentation

This document provides an overview of the local database schema used in the **ICE Gate** application. The database is implemented using **Drift** (SQLite for Dart).

**Database File:** `lib/data_layer/DataSources/local_database/Database.dart`
**Schema Version:** 7

---

## 1. System & Configuration
Tables responsible for app settings, themes, and session management.

| Table Name | Description | Key Columns |
| :--- | :--- | :--- |
| **`ThemesTable`** | Stores locally saved themes. | `themeID`, `name`, `alias`, `json` (content), `author` |
| **`ThemeTable`** | Tracks the currently active theme. | `themeID`, `themeName`, `themePath` |
| **`SessionTable`** | Manages the active user session. | `id`, `jwt`, `username`, `createdAt` |
| **`InternalWidgetsTable`** | Registry of internal system widgets. | `widgetID`, `name`, `url`, `alias`, `imageUrl` |
| **`ExternalWidgetsTable`** | Registry of external/third-party widgets. | `widgetID`, `name`, `protocol`, `host`, `url` |

## 2. User Management & Profile
Core tables for user identity, authentication, and comprehensive profile details.

| Table Name | Description | Key Columns |
| :--- | :--- | :--- |
| **`PersonsTable`** | The central table for a user's identity. | `personID`, `firstName`, `lastName`, `dateOfBirth`, `gender`, `phoneNumber`, `profileImageUrl` |
| **`UserAccountsTable`** | Authentication details for logging in. | `accountID`, `username`, `passwordHash`, `role` (admin/user), `isLocked` |
| **`EmailAddressesTable`** | Email addresses associated with a person. | `emailAddressID`, `emailAddress`, `status` (verified/pending), `isPrimary` |
| **`ProfilesTable`** | General user profile information. | `profileID`, `bio`, `occupation`, `location`, `socialLinks` (github, linkedin) |
| **`CVAddressesTable`** | Specific details used for generating CVs. | `cvAddressID`, `company`, `university`, `educationLevel`, `location`, `bio` |
| **`PersonWidgetsTable`** | Widgets customized and enabled by a user. | `personWidgetID`, `widgetName`, `configuration` (JSON), `displayOrder` |

## 3. Growth & Career
Tables for tracking personal development, skills, and gamification scores.

| Table Name | Description | Key Columns |
| :--- | :--- | :--- |
| **`SkillsTable`** | Professional or personal skills. | `skillID`, `skillName`, `proficiencyLevel`, `yearsOfExperience` |
| **`GoalsTable`** | Long-term or short-term goals. | `goalID`, `title`, `status` (active/done), `priority`, `progressPercentage` |
| **`HabitsTable`** | Habits linked to users or goals. | `habitID`, `habitName`, `frequency`, `targetCount`, `isActive` |
| **`ScoresTable`** | Gamification scores across different life areas. | `scoreID`, `healthGlobalScore`, `socialGlobalScore`, `financialGlobalScore`, `careerGlobalScore` |
| **`ProjectNotesTable`** | Notes related to projects. | `noteID`, `title`, `content` (JSON), `updatedAt` |
| **`BlogPostsTable`** | Blog posts or articles written by the user. | `postID`, `title`, `slug`, `content`, `status` (draft/published), `viewCount` |

## 4. Finance
Tables for tracking financial health and assets.

| Table Name | Description | Key Columns |
| :--- | :--- | :--- |
| **`FinancialAccountsTable`** | Bank accounts, wallets, etc. | `accountID`, `accountName`, `balance`, `currency`, `accountType` |
| **`AssetsTable`** | Physical or digital assets. | `assetID`, `assetName`, `currentEstimatedValue`, `purchasePrice`, `condition` |

## 5. Health & Wellness
Tables for tracking physical health, nutrition, and daily metrics.

| Table Name | Description | Key Columns |
| :--- | :--- | :--- |
| **`HealthMetricsTable`** | Daily aggregation of health stats. | `metricID`, `date`, `steps`, `heartRate`, `sleepHours`, `weightKg`, `caloriesBurned` |
| **`MealsTable`** | Individual meal logs. | `mealID`, `mealName`, `calories`, `macros` (fat/carbs/protein), `eatenAt` |
| **`DaysTable`** | Daily summaries (weight, calories). | `dayID` (DateTime), `weight`, `caloriesOut` |
