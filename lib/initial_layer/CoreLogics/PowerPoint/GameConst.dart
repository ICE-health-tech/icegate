// ─────────────────────────────────────────────────
// 📊 ICE Gate — Global Point Constants
// ─────────────────────────────────────────────────
// Edit these to tune the entire scoring system.

// ─── 🏃 Health ───
const int STEPS_PER_POINT = 500; // 500 steps = 1 point
const int STEP_GOAL = 10000; // Daily step goal
const int CALORIE_LIMIT = 1500; // daily kcal threshold
const int CALORIE_BONUS_POINTS = 20; // bonus if day < 1500 kcal
const int WATER_GOAL = 2000; // ml
const int WATER_BONUS_POINTS = 10; // points if water >= goal
const int EXERCISE_GOAL = 60; // min
const int EXERCISE_PER_POINT = 5; // 5 min = 1 point
const int FOCUS_SESSION_POINTS = 5; // points per completed session
const int FOCUS_MINUTES_PER_POINT = 10; // 10 min = 1 point
const double SLEEP_GOAL = 8.0; // hours
const int SLEEP_POINTS_PER_HOUR = 2; // 1 hour = 2 points
const int WEIGHT_POINTS_PER_KG = 100; // 1 kg = 100 points

// ─── 🧠 Mind (Strategy & Cognitive) ───
const int STRATEGY_NOTE_POINTS = 50; // each strategy note = +50 points
const int MENTAL_MILESTONE_POINTS = 100; // special entries
const int STRATEGY_DEPTH_GOAL = 10; // notes per week?

// ─── 💼 Projects ───
const double TASK_SCORE_INCREMENT = 10; // each task completion = +10
const double PROJECT_SCORE_INCREMENT = 50; // each project completion = +50

// ─── 💰 Finance ───
// Rule: +2 points for every $10 of total net worth = +0.2 points per $1
// This means Point = NetWorth / 5.0
const double FINANCE_NET_WORTH_PER_POINT = 5.0; 
const double USD_TO_VND_RATE = 25450.0; // Current approximate exchange rate

// Historical/Legacy constants (kept for backward compatibility if needed, but discouraged)
const double FINANCE_SAVINGS_MILESTONE = 1000.0;
const int FINANCE_SAVINGS_POINTS = 50; // This was inconsistent with $10=2pts rule (which gives 200 per 1000)

const int FINANCE_SAVINGS_BONUS = 50; // Saving = +50 points
const int FINANCE_BUDGET_ADHERENCE_POINTS = 50; // Staying under budget = +50 points
const double FINANCE_INVESTMENT_RETURN_THRESHOLD = 5.0; // Every 5% return
const double FINANCE_INVESTMENT_POINTS = 10; // ...= +10 points

// ─── Completion Bonuses (Daily) ───
const double STEP_GOAL_BONUS = 15.0;
const double WATER_GOAL_BONUS = 10.0;
const double FOCUS_GOAL_BONUS = 30.0;
const double EXERCISE_GOAL_BONUS = 20.0;
const double SLEEP_GOAL_BONUS = 15.0;
const double CALORIE_LIMIT_BONUS = 20.0;

// ─── Legacy Social (Kept for backward compatibility) ───
const int CONTACT_POINTS = 10;
const int AFFECTION_PER_UNIT = 10;
const int AFFECTION_POINTS = 5;
const double DEFAULT_AFFECTION_INCREASE = 1.0;
