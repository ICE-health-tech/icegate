import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/initial_layer/CoreLogics/Health/AIFoodCaloriesServices.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';

class FoodInputPage extends StatefulWidget {
  final String? mealId;
  final XFile? image;

  const FoodInputPage({super.key, this.mealId, this.image});

  @override
  State<FoodInputPage> createState() => _FoodInputPageState();

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      destination: "/health/food",
      size: size,
      icon: Icons.camera_alt_rounded,
      mainFunction: () {},
    );
  }
}

class _FoodInputPageState extends State<FoodInputPage> {
  final _aiService = Aifoodcaloriesservices();
  final _picker = ImagePicker();

  final _foodController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _kcalController = TextEditingController();

  XFile? _pickedImage;
  String _imagePath = "";
  bool _isAnalyzing = false;
  late HealthMealDAO _healthMealDAO;

  @override
  void initState() {
    super.initState();
    _healthMealDAO = context.read<HealthMealDAO>();

    if (widget.image != null) {
      _pickedImage = widget.image;
      _saveImageAndAnalyze();
    }

    if (widget.mealId != null) {
      _loadMealData();
    }
  }

  Future<void> _saveImageAndAnalyze() async {
    if (_pickedImage == null) return;

    try {
      final authBlock = context.read<AuthBlock>();
      final userData = authBlock.user.value;
      final String personID =
          userData?['person_id']?.toString() ??
          userData?['id']?.toString() ??
          '1';
      final objectBlock = context.read<ObjectDatabaseBlock>();

      final String savedFileName = await objectBlock.saveAnyLocalImage(
        _pickedImage!,
        subFolder: 'meals',
        personId: personID,
      );

      setState(() {
        _imagePath = savedFileName;
      });
      _analyzeFood();
    } catch (e) {
      debugPrint('Error saving image: $e');
    }
  }

  Future<void> _loadMealData() async {
    try {
      final meal = await _healthMealDAO.getMealById(widget.mealId!);
      if (meal != null && mounted) {
        setState(() {
          _foodController.text = meal.mealName;
          _proteinController.text = meal.protein.toString();
          _carbsController.text = meal.carbs.toString();
          _fatController.text = meal.fat.toString();
          _kcalController.text = meal.calories.toString();
          _imagePath = meal.mealImageUrl ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading meal: $e');
    }
  }

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
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) return;

      final authBlock = context.read<AuthBlock>();
      final userData = authBlock.user.value;
      final String personID =
          userData?['person_id']?.toString() ??
          userData?['id']?.toString() ??
          '1';
      final objectBlock = context.read<ObjectDatabaseBlock>();

      final String savedFileName = await objectBlock.saveAnyLocalImage(
        image,
        subFolder: 'meals',
        personId: personID,
      );

      setState(() {
        _pickedImage = image;
        _imagePath = savedFileName;
      });
      _analyzeFood();
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_pickedImage == null && _foodController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _aiService.getCalories(
        _foodController.text,
        image: _pickedImage,
      );

      if (mounted) {
        setState(() {
          _proteinController.text = result.protein.toString();
          _carbsController.text = result.carbs.toString();
          _fatController.text = result.fat.toString();
          _kcalController.text = result.calories.toString();
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

    final authBlock = context.read<AuthBlock>();
    final userData = authBlock.user.value;
    final String personID =
        userData?['person_id']?.toString() ??
        userData?['id']?.toString() ??
        '1';

    final now = DateTime.now();
    final normalizedDate = DateTime(now.year, now.month, now.day);
    final dayDeterministicId = IDGen.generateDeterministicUuid(
      personID,
      DateFormat('yyyy-MM-dd').format(normalizedDate),
    );

    if (widget.mealId != null) {
      final db = context.read<AppDatabase>();
      await (db.update(
        db.mealsTable,
      )..where((t) => t.id.equals(widget.mealId!))).write(
        MealsTableCompanion(
          mealName: Value(
            _foodController.text.isEmpty ? "Meal" : _foodController.text,
          ),
          mealImageUrl: Value(_imagePath),
          carbs: Value(carbs),
          protein: Value(protein),
          fat: Value(fat),
          calories: Value(calories),
        ),
      );
    } else {
      await _healthMealDAO.insertMeal(
        MealsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          mealName: _foodController.text.isEmpty
              ? "Meal"
              : _foodController.text,
          personID: Value(personID),
          mealImageUrl: Value(_imagePath),
          carbs: Value(carbs),
          protein: Value(protein),
          fat: Value(fat),
          calories: Value(calories),
          eatenAt: Value(now),
        ),
      );
    }

    await _healthMealDAO.upsertDay(
      DaysTableCompanion.insert(
        id: dayDeterministicId,
        dayID: normalizedDate,
        caloriesOut: const Value(0),
        weight: const Value(0),
      ),
    );

    if (mounted) {
      WidgetNavigatorAction.smartPop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Log Meal', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => WidgetNavigatorAction.smartPop(context),
        ),
      ),
      body: SwipeablePage(
        direction: SwipeablePageDirection.leftToRight,
        onSwipe: () => WidgetNavigatorAction.smartPop(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_pickedImage != null)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: kIsWeb
                        ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                        : Image.file(
                            File(_pickedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildCaptureModeButton(
                        Icons.camera_alt_rounded,
                        "Camera",
                        colorScheme.primary,
                        () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCaptureModeButton(
                        Icons.photo_library_rounded,
                        "Gallery",
                        colorScheme.secondary,
                        () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              TextField(
                controller: _foodController,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'What did you eat?',
                  prefixIcon: const Icon(Icons.restaurant_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                ),
                onEditingComplete: _analyzeFood,
              ),
              const SizedBox(height: 24),
              Text(
                'NUTRITION INFO',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMacroInput(
                    l10n.nutri_protein,
                    _proteinController,
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildMacroInput(
                    l10n.nutri_carbs,
                    _carbsController,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildMacroInput(l10n.nutri_fat, _fatController, Colors.pink),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _kcalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  labelText: "${l10n.nutri_total} (kcal)",
                  prefixIcon: const Icon(Icons.local_fire_department_rounded),
                  suffixIcon: _isAnalyzing
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.auto_awesome),
                          onPressed: _analyzeFood,
                          color: colorScheme.primary,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _addMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 8,
                  shadowColor: colorScheme.primary.withOpacity(0.4),
                ),
                child: const Text(
                  'SAVE RECORD',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureModeButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInput(
    String label,
    TextEditingController controller,
    Color color,
  ) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}
