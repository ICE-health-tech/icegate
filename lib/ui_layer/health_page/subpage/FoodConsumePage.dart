import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';

class FoodConsumePage extends StatefulWidget {
  const FoodConsumePage({super.key});

  @override
  State<FoodConsumePage> createState() => _FoodConsumePageState();

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      destination: "/health/food/consume",
      size: size,
      icon: Icons.camera_alt_rounded,
      mainFunction: () => context.push('/health/food'),
    );
  }
}

class _FoodConsumePageState extends State<FoodConsumePage> {
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
      appBar: AppBar(
        title: Text(
          l10n.health_log_food,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => WidgetNavigatorAction.smartPop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<DayWithMeal>>(
        stream: _healthMealDAO.watchDaysWithMeals(personID ?? ""),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return _buildEmptyState(l10n, colorScheme);
          }

          final groupedMeals = _groupMealsByDay(data);
          final sortedDays = groupedMeals.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return SwipeablePage(
            direction: SwipeablePageDirection.bottomToTop,
            onSwipe: () => context.push('/health/food/dashboard'),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: sortedDays.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDays[index];
                final dayMeals = groupedMeals[dateKey]!;
                return _buildDaySection(
                  dateKey,
                  dayMeals,
                  l10n,
                  colorScheme,
                  textTheme,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 80,
            color: colorScheme.primary.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.nutri_no_meals,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/health/food'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.add_food),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(
    String dateKey,
    List<DayWithMeal> dayMeals,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;

    final totalCals = dayMeals.fold<double>(
      0,
      (sum, m) => sum + m.meal.calories,
    );
    final totalProtein = dayMeals.fold<double>(
      0,
      (sum, m) => sum + m.meal.protein,
    );
    final totalCarbs = dayMeals.fold<double>(0, (sum, m) => sum + m.meal.carbs);
    final totalFat = dayMeals.fold<double>(0, (sum, m) => sum + m.meal.fat);

    String dayLabel;
    if (isToday) {
      dayLabel = l10n.nutri_today;
    } else if (date == today.subtract(const Duration(days: 1))) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel = DateFormat('EEEE, MMM d').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayLabel,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${totalCals.toInt()} ${l10n.nutri_kcal}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...dayMeals.map(
            (dayWithMeal) => _buildFoodRow(dayWithMeal, l10n, colorScheme),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroTotal(
                  l10n.nutri_fat,
                  totalFat,
                  Colors.pink,
                  colorScheme,
                ),
                _buildMacroTotal(
                  l10n.nutri_carbs,
                  totalCarbs,
                  Colors.blue,
                  colorScheme,
                ),
                _buildMacroTotal(
                  l10n.nutri_protein,
                  totalProtein,
                  Colors.orange,
                  colorScheme,
                ),
                _buildMacroTotal(
                  l10n.nutri_kcal,
                  totalCals,
                  colorScheme.primary,
                  colorScheme,
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTotal(
    String label,
    double value,
    Color color,
    ColorScheme colorScheme, {
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Text(
          isPrimary ? '${value.toInt()}' : '${value.toInt()}g',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isPrimary ? 16 : 14,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodRow(
    DayWithMeal dayWithMeal,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final meal = dayWithMeal.meal;

    return Dismissible(
      key: Key(meal.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.blue,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation();
        } else {
          context.push('/health/food_entry/${meal.id}');
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteMeal(meal.id);
        }
      },
      child: InkWell(
        onTap: () => context.push('/health/food_entry/${meal.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LocalFirstImage(
                  ownerId: meal.personID,
                  localPath: meal.mealImageUrl ?? '',
                  remoteUrl: '',
                  subFolder: 'meals',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: 56,
                    height: 56,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMacroPill('F', meal.fat, Colors.pink),
                        const SizedBox(width: 6),
                        _buildMacroPill('C', meal.carbs, Colors.blue),
                        const SizedBox(width: 6),
                        _buildMacroPill('P', meal.protein, Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal.calories.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    l10n.nutri_cal,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value.toInt()}g',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Meal'),
            content: const Text('Are you sure you want to delete this meal?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteMeal(String mealId) async {
    try {
      final db = context.read<AppDatabase>();
      await (db.delete(db.mealsTable)..where((t) => t.id.equals(mealId))).go();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meal deleted')));
      }
    } catch (e) {
      debugPrint('Error deleting meal: $e');
    }
  }
}
