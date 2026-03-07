import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/initial_layer/CoreLogics/Health/AIFoodCaloriesServices.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';

class FoodDashboardPage extends StatefulWidget {
  const FoodDashboardPage({super.key});

  @override
  State<FoodDashboardPage> createState() => _FoodDashboardPageState();

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      destination: "/health/food/dashboard",
      size: size,
      icon: Icons.camera,
      mainFunction: () => showAddMealDialog(context),
    );
  }

  static void showAddMealDialog(BuildContext context) {
    final aiService = Aifoodcaloriesservices();
    final picker = ImagePicker();
    final healthMealDAO = context.read<HealthMealDAO>();
    final authBlock = context.read<AuthBlock>();
    final userData = authBlock.user.value;
    final String personID =
        userData?['person_id']?.toString() ??
        userData?['id']?.toString() ??
        '1';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _MealDialogContent(
          aiService: aiService,
          picker: picker,
          healthMealDAO: healthMealDAO,
          personID: personID,
        );
      },
    );
  }
}

class _MealDialogContent extends StatefulWidget {
  final Aifoodcaloriesservices aiService;
  final ImagePicker picker;
  final HealthMealDAO healthMealDAO;
  final String personID;

  const _MealDialogContent({
    required this.aiService,
    required this.picker,
    required this.healthMealDAO,
    required this.personID,
  });

  @override
  State<_MealDialogContent> createState() => _MealDialogContentState();
}

class _MealDialogContentState extends State<_MealDialogContent> {
  final _foodController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _kcalController = TextEditingController();
  File? _pickedImage;
  String _imagePath = "";
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _foodController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await widget.picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) return;

      final objectBlock = context.read<ObjectDatabaseBlock>();
      final String savedFileName = await objectBlock.saveAnyLocalImage(
        image,
        subFolder: 'meals',
        personId: widget.personID,
      );

      setState(() {
        _pickedImage = File(image.path); // Keep absolute for temp preview
        _imagePath = savedFileName;
      });
      _analyzeFood();
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_pickedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await widget.aiService.getCalories(
        _foodController.text,
        image: _pickedImage,
      );

      if (mounted) {
        setState(() {
          _proteinController.text = result.protein.toStringAsFixed(1);
          _carbsController.text = result.carbs.toStringAsFixed(1);
          _fatController.text = result.fat.toStringAsFixed(1);
          _kcalController.text = result.calories.toStringAsFixed(0);
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Error analyzing food: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _addMeal() async {
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;
    final calories = double.tryParse(_kcalController.text) ?? 0.0;

    final now = DateTime.now();

    await widget.healthMealDAO.insertMeal(
      MealsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        mealName: _foodController.text.isEmpty ? "Meal" : _foodController.text,
        personID: Value(widget.personID),
        mealImageUrl: Value(_imagePath),
        carbs: Value(carbs),
        protein: Value(protein),
        fat: Value(fat),
        calories: Value(calories),
        eatenAt: Value(now),
      ),
    );

    await widget.healthMealDAO.insertDay(
      DaysTableCompanion.insert(
        id: IDGen.UUIDV7(),
        dayID: now,
        caloriesOut: const Value(0),
        weight: const Value(0),
      ),
    );

    if (mounted) {
      context.go('/health/food');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pickedImage != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_pickedImage!, fit: BoxFit.cover),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: _buildCaptureButton(
                        Icons.camera_alt,
                        "Camera",
                        Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: _buildCaptureButton(
                        Icons.photo_library,
                        "Gallery",
                        Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _foodController,
              decoration: InputDecoration(
                labelText: 'Food Name',
                prefixIcon: const Icon(Icons.restaurant_menu),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: _analyzeFood,
                  tooltip: 'Analyze Food',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onEditingComplete: _analyzeFood,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMacroField('Protein', _proteinController, Colors.orange),
                const SizedBox(width: 8),
                _buildMacroField('Carbs', _carbsController, Colors.blue),
                const SizedBox(width: 8),
                _buildMacroField('Fat', _fatController, Colors.pink),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kcalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Kcal',
                prefixIcon: const Icon(Icons.local_fire_department),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _isAnalyzing
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _addMeal();
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildMacroField(
    String label,
    TextEditingController controller,
    Color color,
  ) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton(IconData icon, String label, Color color) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _FoodDashboardPageState extends State<FoodDashboardPage> {
  late HealthMealDAO _healthMealDAO;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _healthMealDAO = context.read<HealthMealDAO>();
  }

  Map<String, List<DayWithMeal>> _groupMealsByDay(List<DayWithMeal> meals) {
    final Map<String, List<DayWithMeal>> grouped = {};
    for (var meal in meals) {
      final eatenAt = meal.meal.eatenAt;
      final dateKey = DateFormat('yyyy-MM-dd').format(eatenAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(meal);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: StreamBuilder<List<DayWithMeal>>(
        stream: _healthMealDAO.watchDaysWithMeals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          final groupedMeals = _groupMealsByDay(data);
          final sortedDays = groupedMeals.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                title: Text(
                  'Meal Log',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (data.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildMacroOverview(data, sortedDays),
                ),
              if (data.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No meals logged yet',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final dateKey = sortedDays[index];
                      final dayMeals = groupedMeals[dateKey]!;
                      return _buildDayCard(dateKey, dayMeals);
                    }, childCount: sortedDays.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMacroOverview(List<DayWithMeal> data, List<String> sortedDays) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Determine which day to show
    String targetKey = todayKey;
    String displayLabel = "TODAY'S TOTAL";

    if (!sortedDays.contains(todayKey) && sortedDays.isNotEmpty) {
      targetKey = sortedDays.first; // Most recent day
      final date = DateTime.parse(targetKey);
      displayLabel = "${DateFormat('MMM d').format(date).toUpperCase()} TOTAL";
    }

    final targetMeals = data
        .where(
          (m) => DateFormat('yyyy-MM-dd').format(m.meal.eatenAt) == targetKey,
        )
        .toList();

    double p = 0, c = 0, f = 0, kcal = 0;
    for (var entry in targetMeals) {
      p += entry.meal.protein;
      c += entry.meal.carbs;
      f += entry.meal.fat;
      kcal += entry.meal.calories;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${kcal.toInt()} kcal',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroIndicator(
                'Protein',
                p,
                colorScheme.onPrimary,
                Colors.orange,
              ),
              _buildMacroIndicator(
                'Carbs',
                c,
                colorScheme.onPrimary,
                Colors.blue,
              ),
              _buildMacroIndicator(
                'Fat',
                f,
                colorScheme.onPrimary,
                Colors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(
    String label,
    double value,
    Color textColor,
    Color barColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}g',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(String dateKey, List<DayWithMeal> dayMeals) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    double kcal = 0;
    for (var entry in dayMeals) {
      kcal += entry.meal.calories;
    }

    final date = DateTime.parse(dateKey);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${kcal.toInt()} kcal',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...dayMeals.map((meal) => _buildMealRow(meal)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMealRow(DayWithMeal entry) {
    final meal = entry.meal;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {}, // Potential for meal detail view
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildMealImage(meal.mealImageUrl, 70),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.mealName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(meal.eatenAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMacroPill('P', meal.protein, Colors.orange),
                      const SizedBox(width: 6),
                      _buildMacroPill('C', meal.carbs, Colors.blue),
                      const SizedBox(width: 6),
                      _buildMacroPill('F', meal.fat, Colors.pink),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${meal.calories.toInt()}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'cal',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealImage(String? imageName, double size) {
    return LocalFirstImage(
      localPath: imageName ?? '',
      remoteUrl: '',
      subFolder: 'meals',
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: Container(
        width: size,
        height: size,
        color: Colors.grey[100],
        child: const Icon(Icons.restaurant, color: Colors.grey, size: 30),
      ),
    );
  }

  Widget _buildMacroPill(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${value.toInt()}g',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
