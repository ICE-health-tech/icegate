import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:ice_shield/initial_layer/CoreLogics/Health/AIFoodCaloriesServices.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path; // Add this alias to avoid conflicts
import 'package:intl/intl.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';

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
  // final database = AppDatabase();
  bool _isAnalyzing = false;

  final _foodController = TextEditingController();
  final _caloriesController = TextEditingController();
  File? _pickedImage;
  String _imagePath = "";
  final ImagePicker _picker = ImagePicker();
  FlutterSignal<double> totalCalories = signal(0);
  late HealthMealDAO _healthMealDAO;
  late Directory appDir;

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

      print("Path when I pick image: ${image.path}");
      // Sử dụng path_provider

      //  final Directory appDir=await
      final String fileName = path.basename(image.path);
      final File savedImage = await File(
        image.path,
      ).copy('${appDir.path}/$fileName');
      // final String fileName = path.basename(image!.path);
      //   final String permanentPath = '${appDir.path}/$fileName';

      setState(() {
        _pickedImage = File(savedImage.path);
        _imagePath = fileName;
        print("Path when I save image: ${savedImage.path}");
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

      // 2. Insert Day log
      await _healthMealDAO.insertDay(
        DaysTableCompanion.insert(
          id: IDGen.UUIDV7(),
          dayID: now,
          caloriesOut: Value(0),
          weight: Value(0),
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

  Future<void> _getTotalCalories() async {
    final calories = await _healthMealDAO.getCaloriesByDate(DateTime.now());
    if (mounted) {
      totalCalories.value = calories;
    }
  }

  @override
  void initState() {
    super.initState();

    // 1. Initialize the DAO immediately (Provider access is safe here if using context.read)
    _healthMealDAO = context.read<HealthMealDAO>();

    // 2. Load the directory and THEN load calories
    getApplicationDocumentsDirectory().then((dir) {
      if (mounted) {
        setState(() {
          appDir = dir;
        });
        _getTotalCalories(); // Now safe to call
      }
    });
  }

  // Remove didChangeDependencies entirely unless you have other logic there
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            title: Text(
              'Food Tracker',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            iconTheme: IconThemeData(color: colorScheme.onSurface),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
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
                              "TODAY'S INTAKE",
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary.withOpacity(0.7),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Watch((context) {
                              return Text(
                                '${totalCalories.value.toInt()} kcal',
                                style: textTheme.displaySmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              );
                            }),
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
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Simple progress indicator (Target e.g. 2000)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Watch((context) {
                        return LinearProgressIndicator(
                          value: (totalCalories.value / 2000).clamp(0, 1),
                          backgroundColor: colorScheme.onPrimary.withOpacity(
                            0.2,
                          ),
                          color: Colors.white,
                          minHeight: 8,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Recent Meals',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<List<DayWithMeal>>(
                stream: _healthMealDAO.watchDaysWithMeals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final mealsList = snapshot.data ?? [];
                  // print("meal list: " + mealsList.toList().toString());

                  if (mealsList.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No meals logged yet",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.4,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mealsList.length,
                    itemBuilder: (context, index) {
                      final entry = mealsList[index];
                      final meal = entry.meal;
                      final mealType = _timeInDay(meal.eatenAt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Meal Image
                                _buildMealImage(meal.mealImageUrl, 90),

                                // Meal Details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                meal.mealName,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: -0.5,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildBadge(
                                              mealType['label']!,
                                              Color(mealType['color']!),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'h:mm a • MMM d',
                                          ).format(meal.eatenAt),
                                          style: textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant
                                                .withOpacity(0.6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _buildMacroText(
                                              'P',
                                              meal.protein,
                                              Colors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            _buildMacroText(
                                              'C',
                                              meal.carbs,
                                              Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            _buildMacroText(
                                              'F',
                                              meal.fat,
                                              Colors.pink,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Calorie Count
                                Container(
                                  width: 70,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withOpacity(0.1),
                                    border: Border(
                                      left: BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withOpacity(0.5),
                                      ),
                                    ),
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
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary
                                              .withOpacity(0.7),
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
                    },
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    if (imageName == null || imageName.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[100],
        child: const Icon(Icons.restaurant, color: Colors.grey, size: 30),
      );
    }

    final file = File('${appDir.path}/$imageName');
    return Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        color: Colors.grey[100],
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
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

  Widget _buildMacroText(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${value.toInt()}g',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
      ],
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
