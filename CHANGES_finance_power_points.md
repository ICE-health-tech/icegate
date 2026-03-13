# Finance Power Points Update

## Overview
Added the "Finance Power" feature to the Finance dashboard to calculate and display user points based on their total net worth. This aligns the Finance pillar with the Gamification Service scoring logic.

## Changes Made
1. **Business Logic (`FinanceBlock.dart`)**:
   - Added a new `financePoints` computed signal to calculate points using the formula: `(totalBalance.value / FINANCE_SAVINGS_MILESTONE) * FINANCE_SAVINGS_POINTS`.

2. **Localization (`app_en.arb`, `app_vi.arb`)**:
   - Added localization keys for "FINANCE POWER" (`finance_power_points`) and its description (`finance_points_desc`).

3. **UI/UX (`FinancePage.dart`)**:
   - Integrated the `financePoints` value directly into the portfolio header using an animated visual chip.
   - Added a progress bar to visually represent progress towards the next $1,000 milestone unit.
   - Replaced deprecated `.withOpacity` methods with `.withValues(alpha: ...)` to align with newer Flutter standards and maintain precision.

## Impact
Users can now visually track their financial points and how they progress towards the next milestone, boosting gamification engagement within the Finance app pillar.
