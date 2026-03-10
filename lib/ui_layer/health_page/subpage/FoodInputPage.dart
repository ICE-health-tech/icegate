import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:ice_gate/initial_layer/CoreLogics/Health/AIFoodCaloriesServices.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/components/NutritionRingChart.dart';

class FoodInputPage extends StatefulWidget {
  const FoodInputPage({super.key});

  @override
  State<FoodInputPage> createState() => _FoodInputPageState();
  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "health",
      destination: "/health",
      size: size,
      mainFunction: () {
        print("Main button clicked");
        context.go('/health/food/dashboard');
      },
      icon: Icons.sunny,
      subButtons: [
        SubButton(
          icon: Icons.restaurant,
          // size: 100,
          backgroundColor: Colors.orange,
          onPressed: () {
            print("Main button clicked");
            context.go('/health/food');
          },
        ),
        SubButton(
          icon: Icons.fitness_center,
          backgroundColor: Colors.red,
          onPressed: () => context.go('/health/exercise'),
        ),
        SubButton(
          icon: Icons.bedtime,
          backgroundColor: Colors.indigo,
          onPressed: () => context.go('/health/sleep'),
        ),
        SubButton(
          icon: Icons.water_drop,
          backgroundColor: Colors.cyan,
          onPressed: () {
            context.go('/health/water');
            // print("Water button clicked");
          },
        ),
      ],
      // isShow: false,
      // onPressed: () {
      //   setState(() {
      //     isShow=true;
      //   })
      // },
    );
  }
}

class _FoodInputPageState extends State<FoodInputPage> {
  final _aiService = Aifoodcaloriesservices();
  bool _isAnalyzing = false;

  final _foodController = TextEditingController();
  final _caloriesController = TextEditingController();
  File? _pickedImage;
  String _imagePath = "";
  final ImagePicker _picker = ImagePicker();
  late HealthMealDAO _healthMealDAO;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) {
        print("No image selected");
        return;
      }

      final objectBlock = context.read<ObjectDatabaseBlock>();
      final authBlock = context.read<AuthBlock>();
      final userData = authBlock.user.value;
      final String personID =
          userData?['person_id']?.toString() ??
          userData?['id']?.toString() ??
          '1';

      final String savedFileName = await objectBlock.saveAnyLocalImage(
        image,
        subFolder: 'meals',
        personId: personID,
      );

      setState(() {
        _pickedImage = File(image.path); // Keep absolute for temp preview
        _imagePath = savedFileName;
        print("Standardized save - filename: $savedFileName");
      });
      // Trigger AI analysis if food name is also present or just analysis from image
      _analyzeFood();
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_pickedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final calories = await _aiService.getCalories(
        _foodController.text,
        image: _pickedImage,
      );

      if (mounted) {
        setState(() {
          _caloriesController.text =
              "${calories.carbs}|${calories.protein}|${calories.fat}|${calories.calories}";
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Error analyzing food: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _addMeal() async {
    if (_caloriesController.text.isNotEmpty) {
      // print(_caloriesController.text);
      if (_foodController.text.isEmpty) {
        _foodController.text = _timeInDay(DateTime.now())['label']!;
      }
      final energy = _caloriesController.text.split("|");

      final carbs = double.tryParse(energy[0]) ?? 0.0;
      final protein = double.tryParse(energy[1]) ?? 0.0;
      final fat = double.tryParse(energy[2]) ?? 0.0;
      final calories = double.tryParse(energy[3]) ?? 0.0;

      // final totalCalories = (carbs + protein + fat).toInt();

      final now = DateTime.now();

      final authBlock = context.read<AuthBlock>();
      final userData = authBlock.user.value;
      final String personID =
          userData?['person_id']?.toString() ??
          userData?['id']?.toString() ??
          '1';

      final normalizedDate = DateTime(now.year, now.month, now.day);
      final dayDeterministicId = IDGen.generateDeterministicUuid(
        personID,
        DateFormat('yyyy-MM-dd').format(normalizedDate),
      );

      // 1. Insert Meal details
      await _healthMealDAO.insertMeal(
        MealsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          mealName: _foodController.text,
          personID: Value(personID),
          mealImageUrl: Value(_imagePath),
          carbs: Value(carbs),
          protein: Value(protein),
          fat: Value(fat),
          calories: Value(calories),
          eatenAt: Value(now),
        ),
      );

      // 2. Insert Day log (upsert)
      await _healthMealDAO.upsertDay(
        DaysTableCompanion.insert(
          id: dayDeterministicId,
          dayID: normalizedDate,
          caloriesOut: const Value(0),
          weight: const Value(0),
        ),
      );

      setState(() {
        // _meals.add({
        //   'name': _foodController.text,
        //   'calories': calories.toInt(),
        //   'time': now.toString(),
        //   'image': _pickedImage,
        // });
        _foodController.clear();
        _caloriesController.clear();
        _pickedImage = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // 1. Initialize the DAO immediately (Provider access is safe here if using context.read)
    _healthMealDAO = context.read<HealthMealDAO>();
  }

  // Remove didChangeDependencies entirely unless you have other logic there
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final personID = context.read<PersonBlock>().currentPersonID.value;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCaptureOptions(context),
        label: Text(
          'Log Meal',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colorScheme.onPrimary,
          ),
        ),
        icon: Icon(Icons.add_a_photo_rounded, color: colorScheme.onPrimary),
        backgroundColor: colorScheme.primary,
        elevation: 4,
      ),
      body: StreamBuilder<List<DayWithMeal>>(
        stream: _healthMealDAO.watchDaysWithMeals(personID ?? ""),
        builder: (context, snapshot) {
          final mealsList = snapshot.data ?? [];

          // Calculate macros for today
          double p = 0, c = 0, f = 0, kcal = 0;
          final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          for (var entry in mealsList) {
            if (DateFormat('yyyy-MM-dd').format(entry.meal.eatenAt) ==
                todayKey) {
              p += entry.meal.protein;
              c += entry.meal.carbs;
              f += entry.meal.fat;
              kcal += entry.meal.calories;
            }
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 460,
                collapsedHeight: 80,
                floating: false,
                pinned: true,
                elevation: 0,
                stretch: true,
                backgroundColor: colorScheme.primary,
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  centerTitle: true,
                  title: Text(
                    'Nutrition Analysis',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Premium Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                              colorScheme.secondary.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                      // Decorative elements
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            NutritionRingChart(
                              calories: kcal,
                              calorieGoal:
                                  2000, // Hardcoded for now, can be signal based
                              protein: p,
                              carbs: c,
                              fat: f,
                            ),
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMacroSummaryItem(
                                    context,
                                    'Protein',
                                    p,
                                    150,
                                    Colors.orange,
                                  ),
                                  _buildMacroSummaryItem(
                                    context,
                                    'Carbs',
                                    c,
                                    250,
                                    Colors.blue,
                                  ),
                                  _buildMacroSummaryItem(
                                    context,
                                    'Fat',
                                    f,
                                    70,
                                    Colors.pink,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => context.go('/health/food/dashboard'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Logged',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/health/food/dashboard'),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (mealsList.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_rounded,
                          size: 80,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Your plate is empty today",
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = mealsList[index];
                      return _buildEnhancedMealCard(context, entry);
                    }, childCount: mealsList.length > 5 ? 5 : mealsList.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMacroSummaryItem(
    BuildContext context,
    String label,
    double value,
    double goal,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}g',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMealCard(BuildContext context, DayWithMeal entry) {
    final meal = entry.meal;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mealType = _timeInDay(meal.eatenAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Meal Image with subtle overlay
              Stack(
                children: [
                  _buildMealImage(meal.mealImageUrl, 110),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBadge(
                            mealType['label']!,
                            Color(mealType['color']!),
                          ),
                          Text(
                            DateFormat('h:mm a').format(meal.eatenAt),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal.mealName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _buildMacroPill('P', meal.protein, Colors.orange),
                          const SizedBox(width: 8),
                          _buildMacroPill('C', meal.carbs, Colors.blue),
                          const SizedBox(width: 8),
                          _buildMacroPill('F', meal.fat, Colors.pink),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 70,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${meal.calories.toInt()}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary.withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${value.toInt()}g',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _showCaptureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _pickImage(ImageSource.camera).then((_) {
                  if (_pickedImage != null) {
                    _showAddMealDialog(context, _pickedImage);
                  }
                });
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _pickImage(ImageSource.gallery).then((_) {
                  if (_pickedImage != null) {
                    _showAddMealDialog(context, _pickedImage);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, File? image) {
    // If an image was passed in, set it as the picked image
    if (image != null) {
      _pickedImage = image;
      // Trigger analysis automatically if image is provided
      _analyzeFood();
    } else {
      // Clear if manual mode
      _pickedImage = null;
      _imagePath = "";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(image != null ? 'Edit Captured Meal' : 'Add Meal'),
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
                  ),
                if (_pickedImage == null)
                  GestureDetector(
                    onTap: () {
                      // Fallback for manual adding photo inside dialog
                      Navigator.pop(context);
                      _showCaptureOptions(context);
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          Text(
                            "Add Photo (Optional)",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _foodController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(),
                  ),
                  onEditingComplete: _analyzeFood,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _caloriesController,
                  decoration: InputDecoration(
                    labelText: 'Energy',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isAnalyzing
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.auto_awesome),
                            onPressed: _analyzeFood,
                            tooltip: 'Analyze Food',
                          ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _pickedImage = null;
                Navigator.pop(context);
              },
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
        ),
      ),
    );
  }

  Widget _buildMealImage(String? imageName, double size) {
    final authBlock = context.read<AuthBlock>();
    final userData = authBlock.user.value;
    final String? personID =
        userData?['person_id']?.toString() ?? userData?['id']?.toString();

    return LocalFirstImage(
      ownerId: personID,
      localPath: imageName ?? '',
      remoteUrl: '', // No remote meals storage currently implemented
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

Map<String, dynamic> _timeInDay(DateTime time) {
  final hour = time.hour;

  if (hour >= 5 && hour < 12) {
    return {'label': 'BREAKFAST', 'color': 0xFFFFB74D}; // Orange
  } else if (hour >= 12 && hour < 17) {
    return {'label': 'LUNCH', 'color': 0xFF81C784}; // Green
  } else if (hour >= 17 && hour < 21) {
    return {'label': 'DINNER', 'color': 0xFF64B5F6}; // Blue
  } else {
    return {'label': 'Snack', 'color': 0xFFBA68C8}; // Purple
  }
}
