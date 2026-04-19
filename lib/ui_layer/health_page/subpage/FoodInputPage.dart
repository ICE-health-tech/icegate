import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:ice_gate/ui_layer/ReusableWidget/UIResponsiveManager.dart';
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
      // WidgetNavigatorAction.smartPop(context);
      context.go("/health/food/consume");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final padding = UIResponsiveManager.padding(context);
    final inputFieldSpacing = UIResponsiveManager.inputFieldSpacing(context, factor: 2);
    final imageHeight = UIResponsiveManager.responsiveValue(
      context,
      phone: 200,
      tablet: 280,
      laptop: 320,
      desktop: 350,
    );
    final imageRadius = UIResponsiveManager.cardRadius(context);
    final buttonRadius = UIResponsiveManager.responsiveValue(
      context,
      phone: 20,
      tablet: 24,
      laptop: 28,
      desktop: 32,
    );
    final iconSize = UIResponsiveManager.iconSize(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Log Meal', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: iconSize - 4),
          onPressed: () => WidgetNavigatorAction.smartPop(context),
        ),
      ),
      body: SwipeablePage(
        direction: SwipeablePageDirection.leftToRight,
        onSwipe: () => WidgetNavigatorAction.smartPop(context),
        child: SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: UIResponsiveManager.responsiveValue(
                  context,
                  phone: double.infinity,
                  tablet: double.infinity,
                  laptop: double.infinity,
                  desktop: double.infinity,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pickedImage != null)
                    Container(
                      height: imageHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(imageRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: UIResponsiveManager.inputFieldSpacing(
                              context,
                              factor: 2,
                            ),
                            offset: Offset(
                              0,
                              UIResponsiveManager.inputFieldSpacing(context, factor: 1),
                            ),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(imageRadius),
                        child: kIsWeb
                            ? Image.network(
                                _pickedImage!.path,
                                fit: BoxFit.cover,
                              )
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
                        SizedBox(
                          width: UIResponsiveManager.horizontalSpacing(context),
                        ),
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
                  SizedBox(height: inputFieldSpacing * 1.5),
                  TextField(
                    controller: _foodController,
                    style: TextStyle(
                      fontSize:
                          UIResponsiveManager.responsiveFontScale(context) * 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'What did you eat?',
                      prefixIcon: Icon(
                        Icons.restaurant_rounded,
                        size: iconSize,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    onEditingComplete: _analyzeFood,
                  ),
                  SizedBox(height: inputFieldSpacing),
                  Text(
                    'NUTRITION INFO',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                      letterSpacing:  1.5,
                    ),
                  ),
                  SizedBox(height: UIResponsiveManager.inputFieldSpacing(context)),
                  Row(
                    children: [
                      _buildMacroInput(
                        l10n.nutri_protein,
                        _proteinController,
                        Colors.orange,
                      ),
                      SizedBox(width: UIResponsiveManager.inputFieldSpacing(context)),
                      _buildMacroInput(
                        l10n.nutri_carbs,
                        _carbsController,
                        Colors.blue,
                      ),
                      SizedBox(width: UIResponsiveManager.inputFieldSpacing(context)),
                      _buildMacroInput(
                        l10n.nutri_fat,
                        _fatController,
                        Colors.pink,
                      ),
                    ],
                  ),
                  SizedBox(height: inputFieldSpacing),
                  TextField(
                    controller: _kcalController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize:
                          UIResponsiveManager.responsiveFontScale(context) * 20,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      labelText: "${l10n.nutri_total} (kcal)",
                      prefixIcon: Icon(
                        Icons.local_fire_department_rounded,
                        size: iconSize,
                      ),
                      suffixIcon: _isAnalyzing
                          ? Padding(
                              padding: EdgeInsets.all(
                                UIResponsiveManager.inputFieldSpacing(context) * 0.75,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.auto_awesome),
                              onPressed: _analyzeFood,
                              color: colorScheme.primary,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                    ),
                  ),
                  SizedBox(height: inputFieldSpacing * 2),
                  ElevatedButton(
                    onPressed: _addMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        vertical: UIResponsiveManager.inputFieldSpacing(
                          context,
                          factor: 1.5,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius + 4),
                      ),
                      elevation: UIResponsiveManager.cardElevation(context),
                      shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      'SAVE RECORD',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize:
                            UIResponsiveManager.responsiveFontScale(context) *
                            14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    final radius = UIResponsiveManager.cardRadius(context);
    final iconSize = UIResponsiveManager.iconSize(context) + 16;
    final inputFieldSpacing = UIResponsiveManager.inputFieldSpacing(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: inputFieldSpacing * 2.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: inputFieldSpacing),
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
    final radius = UIResponsiveManager.cardRadius(context) - 4;
    final borderWidth = UIResponsiveManager.borderWidth(context);

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
            fontSize: UIResponsiveManager.responsiveFontScale(context) * 12,
          ),
          contentPadding: EdgeInsets.all(
            UIResponsiveManager.inputFieldSpacing(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: color, width: borderWidth + 1),
          ),
        ),
      ),
    );
  }
}
