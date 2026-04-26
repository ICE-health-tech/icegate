import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/AIFoodCaloriesServices.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/FoodDataCentralService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/LidarFoodScanner.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:path_provider/path_provider.dart';

class FoodInputPage extends StatefulWidget {
  final String? mealId;
  final XFile? image;
  final bool isPopUp;

  const FoodInputPage({
    super.key,
    this.mealId,
    this.image,
    this.isPopUp = false,
  });

  @override
  State<FoodInputPage> createState() => _FoodInputPageState();

  static Future<void> show(
    BuildContext context, {
    String? mealId,
    XFile? image,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FoodInputPage(mealId: mealId, image: image, isPopUp: true),
    );
  }

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      destination: "/health/food",
      size: size,
      icon: Icons.camera_alt_rounded,
      mainFunction: () => show(context),
    );
  }
}

class _FoodInputPageState extends State<FoodInputPage> {
  final _picker = ImagePicker();

  final _foodController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _kcalController = TextEditingController();

  XFile? _pickedImage;
  String _imagePath = "";
  bool _isAnalyzing = false;
  double? _measuredVolume;
  Map<String, double>? _dimensions;
  Map<String, dynamic>? _fdcData;
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

  void _calculateKcal() {
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    final total = (protein * 4) + (carbs * 4) + (fat * 9);
    setState(() {
      _kcalController.text = total.toStringAsFixed(0);
    });
  }

  Future<void> _analyzeFood() async {
    if (_pickedImage == null && _foodController.text.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      // 1. First, if we have a name, try to get official data from FoodData Central
      if (_foodController.text.isNotEmpty) {
        final fdc = await FoodDataCentralService.searchFood(
          _foodController.text,
        );
        if (fdc != null) {
          setState(() => _fdcData = fdc);
          // Pre-fill if we have a good match and no LiDAR yet
          if (_measuredVolume == null) {
            _proteinController.text = fdc['protein'].toString();
            _carbsController.text = fdc['carbs'].toString();
            _fatController.text = fdc['fat'].toString();
            _kcalController.text = fdc['calories'].toString();
          }
        }
      }

      // 2. Call AI with all available context (Image, LiDAR, FDC data)
      final result = await AIFoodCaloriesService.getCalories(
        _foodController.text,
        image: _pickedImage,
        volume: _measuredVolume,
        distance: _dimensions?['length'], // Using length as a primary dimension
        fdcData: _fdcData,
      );

      if (mounted) {
        setState(() {
          // If we have official data AND LiDAR, we can scale the FDC data
          // But for now, let's trust the AI which combines both
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

  Future<void> _startLidarScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LidarFoodScanner()),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (result['image'] != null) {
        try {
          // Handle AR snapshot
          final imageProvider = result['image'] as ImageProvider;
          if (imageProvider is MemoryImage) {
            final directory = await getTemporaryDirectory();
            final filePath =
                '${directory.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(filePath);
            await file.writeAsBytes(imageProvider.bytes);
            setState(() {
              _pickedImage = XFile(filePath);
            });
            _saveImageAndAnalyze();
          }
        } catch (e) {
          debugPrint('Error saving AR snapshot: $e');
        }
      }

      setState(() {
        _measuredVolume = result['volume'];
        _dimensions = result['dimensions']?.cast<String, double>();
      });
      _analyzeFood(); // Re-analyze with new LiDAR context
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
      if (widget.isPopUp) {
        Navigator.of(context).pop();
      } else {
        context.go("/health/food/consume");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Obsidian/Premium Design System
    const obsidianBg = Color(0xFF0F0716);
    const obsidianCard = Color(0xFF1A1024);
    const obsidianBorder = Color(0xFF322244);
    const premiumPink = Color(0xFFD499D4);

    return Scaffold(
      backgroundColor: obsidianBg,
      appBar: AppBar(
        toolbarHeight: 200,
        title: Column(
          children: [
            Text(
              l10n.nutri_add_meal.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D85), // premiumPink
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SwipeablePage(
        direction: SwipeablePageDirection.leftToRight,
        onSwipe: () => Navigator.of(context).pop(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Preview Section
              _buildIntegratedImageSection(
                context,
                obsidianCard,
                obsidianBorder,
                premiumPink,
              ),

              const SizedBox(height: 16),

              // 2. Food Name Input
              _buildObsidianTextField(
                controller: _foodController,
                hintText: l10n.nutri_what_eat,
                icon: Icons.restaurant_rounded,
                obsidianBg: obsidianCard,
                obsidianBorder: obsidianBorder,
                onEditingComplete: _analyzeFood,
              ),

              const SizedBox(height: 16),

              // 3. Nutrition Info Title
              Text(
                'THÔNG TIN DINH DƯỠNG',
                style: TextStyle(
                  color: premiumPink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // 4. Macros Grid
              Row(
                children: [
                  _buildMacroInput(
                    'Đạm',
                    _proteinController,
                    Colors.orange,
                    obsidianCard,
                    obsidianBorder,
                  ),
                  const SizedBox(width: 12),
                  _buildMacroInput(
                    'Tinh bột',
                    _carbsController,
                    Colors.blue,
                    obsidianCard,
                    obsidianBorder,
                  ),
                  const SizedBox(width: 12),
                  _buildMacroInput(
                    'Chất béo',
                    _fatController,
                    Colors.pink,
                    obsidianCard,
                    obsidianBorder,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Total Calories
              _buildObsidianTextField(
                controller: _kcalController,
                hintText: '${l10n.nutri_total} (kcal)',
                icon: Icons.local_fire_department_rounded,
                obsidianBg: obsidianCard,
                obsidianBorder: obsidianBorder,
                isCalories: true,
                isAnalyzing: _isAnalyzing,
              ),

              const SizedBox(height: 32),

              // 6. Save Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _addMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: premiumPink,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isAnalyzing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.nutri_save_record.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegratedImageSection(
    BuildContext context,
    Color cardBg,
    Color border,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_pickedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.file(
                File(_pickedImage!.path),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_enhance_rounded,
                    size: 48,
                    color: accent.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to Capture or 3D Scan',
                    style: TextStyle(
                      color: accent.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons Overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              children: [
                _buildSmallActionCircle(
                  Icons.camera_alt_rounded,
                  () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 8),
                _buildSmallActionCircle(
                  Icons.photo_library_rounded,
                  () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 8),
                _buildSmallActionCircle(
                  Icons.view_in_ar_rounded,
                  _startLidarScan,
                  isScan: true,
                ),
              ],
            ),
          ),

          if (_pickedImage != null)
            Positioned(
              top: 12,
              right: 12,
              child: _buildSmallActionCircle(
                Icons.close_rounded,
                () => setState(() => _pickedImage = null),
                isClose: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallActionCircle(
    IconData icon,
    VoidCallback onTap, {
    bool isScan = false,
    bool isClose = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isScan
              ? Colors.deepPurple
              : (isClose ? Colors.red.withOpacity(0.8) : Colors.black54),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          boxShadow: isScan
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildObsidianTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color obsidianBg,
    required Color obsidianBorder,
    bool isCalories = false,
    bool isAnalyzing = false,
    VoidCallback? onEditingComplete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: obsidianBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: obsidianBorder, width: 2),
      ),
      child: TextField(
        controller: controller,
        onEditingComplete: onEditingComplete,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(
            icon,
            color: isCalories ? Colors.orange : Colors.white70,
          ),
          suffixIcon: isCalories && isAnalyzing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                )
              : (isCalories
                    ? IconButton(
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.orange,
                        ),
                        onPressed: _analyzeFood,
                      )
                    : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMacroInput(
    String label,
    TextEditingController controller,
    Color color,
    Color obsidianBg,
    Color obsidianBorder,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: obsidianBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: (_) => _calculateKcal(),
            ),
          ],
        ),
      ),
    );
  }
}
