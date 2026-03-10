import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/components/NutritionRingChart.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';

class FoodDashboardPage extends StatefulWidget {
  const FoodDashboardPage({super.key});

  @override
  State<FoodDashboardPage> createState() => _FoodDashboardPageState();

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      destination: "/health/food/dashboard",
      size: size,
      icon: Icons.analytics_outlined,
      mainFunction: () {},
    );
  }
}

class _FoodDashboardPageState extends State<FoodDashboardPage> {
  late HealthMealDAO _healthMealDAO;

  @override
  void initState() {
    super.initState();
    _healthMealDAO = context.read<HealthMealDAO>();
  }

  Map<String, List<DayWithMeal>> _groupMealsByDay(List<DayWithMeal> meals) {
    final Map<String, List<DayWithMeal>> grouped = {};
    for (var meal in meals) {
      final dateKey = DateFormat('yyyy-MM-dd').format(meal.meal.eatenAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(meal);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final personID = context.read<PersonBlock>().currentPersonID.value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/food'),
        label: Text(
          'LOG MEAL',
          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onPrimary),
        ),
        icon: Icon(Icons.add_rounded, color: colorScheme.onPrimary),
        backgroundColor: colorScheme.primary,
        elevation: 4,
      ),
      body: StreamBuilder<List<DayWithMeal>>(
        stream: _healthMealDAO.watchDaysWithMeals(personID ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          final groupedMeals = _groupMealsByDay(data);
          final sortedDays = groupedMeals.keys.toList()..sort((a, b) => b.compareTo(a));

          // Calculate today's totals
          double p = 0, c = 0, f = 0, kcal = 0;
          final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          for (var entry in data) {
            if (DateFormat('yyyy-MM-dd').format(entry.meal.eatenAt) == todayKey) {
              p += entry.meal.protein;
              c += entry.meal.carbs;
              f += entry.meal.fat;
              kcal += entry.meal.calories;
            }
          }

          return SwipeablePage(
            direction: SwipeablePageDirection.leftToRight,
            onSwipe: () => WidgetNavigatorAction.smartPop(context),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 460,
                  collapsedHeight: 80,
                  pinned: true,
                  stretch: true,
                  backgroundColor: colorScheme.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => WidgetNavigatorAction.smartPop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      l10n.nutrition_dashboard,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    centerTitle: true,
                    background: _buildHeader(kcal, p, c, f),
                  ),
                ),
                if (data.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildTrendSection(data)),
                  SliverToBoxAdapter(child: _buildNutritionInsights(data)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'RECENT LOGGED',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final dateKey = sortedDays[index];
                          final dayMeals = groupedMeals[dateKey]!;
                          return _buildDayCard(dateKey, dayMeals);
                        },
                        childCount: sortedDays.length,
                      ),
                    ),
                  ),
                ] else
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu_rounded, size: 80, color: colorScheme.primary.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text(l10n.nutri_no_meals, style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5))),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(double kcal, double p, double c, double f) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            NutritionRingChart(
              calories: kcal,
              calorieGoal: CALORIE_LIMIT.toDouble(),
              protein: p,
              carbs: c,
              fat: f,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMacroSummary(l10n.nutri_protein, p, Colors.orange),
                _buildMacroSummary(l10n.nutri_carbs, c, Colors.blue),
                _buildMacroSummary(l10n.nutri_fat, f, Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSummary(String label, double value, Color color) {
    return Column(
      children: [
        Text('${value.toInt()}g', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10)),
      ],
    );
  }

  Widget _buildTrendSection(List<DayWithMeal> data) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final Map<String, double> dailyCals = {};

    for (int i = 6; i >= 0; i--) {
      final key = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      dailyCals[key] = 0.0;
    }
    for (var entry in data) {
      final key = DateFormat('yyyy-MM-dd').format(entry.meal.eatenAt);
      if (dailyCals.containsKey(key)) {
        dailyCals[key] = (dailyCals[key] ?? 0) + entry.meal.calories;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.nutri_trends_title.toUpperCase(), 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: colorScheme.primary, letterSpacing: 1.2)),
              Text(l10n.nutri_weekly_calories_chart, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 24),
          SimpleLineChart(data: dailyCals.values.toList(), color: colorScheme.primary, height: 100),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dailyCals.keys.map((k) => Text(DateFormat('E').format(DateTime.parse(k))[0], 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInsights(List<DayWithMeal> data) {
    final l10n = AppLocalizations.of(context)!;

    double totalCals = 0;
    double totalProtein = 0;
    int dayCount = 0;
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final key = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      final dayMeals = data.where((m) => DateFormat('yyyy-MM-dd').format(m.meal.eatenAt) == key).toList();
      if (dayMeals.isNotEmpty) {
        dayCount++;
        for (var m in dayMeals) {
          totalCals += m.meal.calories;
          totalProtein += m.meal.protein;
        }
      }
    }

    if (dayCount == 0) return const SizedBox.shrink();
    final avgCals = totalCals / dayCount;
    final avgProtein = totalProtein / dayCount;

    String advice = l10n.nutri_advice_good_job;
    IconData icon = Icons.check_circle_outline;
    Color adviceColor = Colors.green;

    if (avgCals > CALORIE_LIMIT) {
      advice = l10n.nutri_advice_high_cal;
      icon = Icons.warning_amber_rounded;
      adviceColor = Colors.orange;
    } else if (avgProtein < 40) {
      advice = l10n.nutri_advice_low_protein;
      icon = Icons.info_outline;
      adviceColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adviceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: adviceColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: adviceColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nutri_insights_title.toUpperCase(), 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: adviceColor, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(advice, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String dateKey, List<DayWithMeal> dayMeals) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.parse(dateKey);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
    final totalCals = dayMeals.fold<double>(0, (sum, m) => sum + m.meal.calories);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isToday ? l10n.nutri_today : DateFormat('EEEE, MMM d').format(date), 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text('${totalCals.toInt()} ${l10n.nutri_kcal}', 
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          ...dayMeals.map((m) => _buildMealRow(m, l10n)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMealRow(DayWithMeal entry, AppLocalizations l10n) {
    final meal = entry.meal;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LocalFirstImage(
              ownerId: meal.personID,
              localPath: meal.mealImageUrl ?? '',
              remoteUrl: '',
              subFolder: 'meals',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.mealName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text(DateFormat('h:mm a').format(meal.eatenAt), 
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.6))),
              ],
            ),
          ),
          Text('${meal.calories.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(width: 2),
          Text(l10n.nutri_cal, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
