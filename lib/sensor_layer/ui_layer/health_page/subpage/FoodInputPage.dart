import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/LidarFoodScanner.dart';

import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';

import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FoodAnalysisBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';

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
  late HealthMealDAO _healthMealDAO;
  Timer? _analysisTimer;
  bool _isSaving = false;
  bool _needsAiRetry = false;

  /// Must match [FoodConsumePage] / [FoodDashboardPage] list query or rows disappear.
  String _mealsPersonIdForQuery() {
    final userData = context.read<AuthBlock>().user.value;
    final fromAuth =
        userData?['person_id']?.toString() ?? userData?['id']?.toString();
    if (fromAuth != null && fromAuth.isNotEmpty) {
      return fromAuth;
    }
    final fromProfile = context.read<PersonBlock>().currentPersonID.value;
    if (fromProfile != null && fromProfile.isNotEmpty) {
      return fromProfile;
    }
    return '1';
  }

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
      if (!mounted) return;
      final String personID = _mealsPersonIdForQuery();
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
          _needsAiRetry = meal.needsAiRetry;
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
    _analysisTimer?.cancel();
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

      if (!mounted) return;
      final String personID = _mealsPersonIdForQuery();
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
    _analysisTimer?.cancel();

    _analysisTimer = Timer(const Duration(seconds: 2), () {
      if (_isAnalyzing && mounted && !_isSaving) {
        _addMeal(); // Auto-save and close for faster UX
      }
    });

    try {
      if (!mounted) return;
      final String personID = _mealsPersonIdForQuery();

      final analysisBlock = context.read<FoodAnalysisBlock>();
      final outcome = await analysisBlock.analyze(
        foodName: _foodController.text,
        image: _pickedImage,
        volume: _measuredVolume,
        distance: _dimensions?['length'],
        personId: personID,
      );

      if (mounted) {
        final r = outcome.protocol;
        setState(() {
          _proteinController.text = r.protein.toString();
          _carbsController.text = r.carbs.toString();
          _fatController.text = r.fat.toString();
          _kcalController.text = r.calories.toString();
          if (r.imageUrl != null && r.imageUrl!.isNotEmpty) {
            _imagePath = r.imageUrl!;
          }
          _isAnalyzing = false;
          _needsAiRetry = !outcome.aiSucceeded;
        });
        _analysisTimer?.cancel();

        if (!_isSaving) {
          await _addMeal();
        }

        if (!outcome.aiSucceeded) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.nutri_ai_saved_retry_later,
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('FoodInputPage: Analysis error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _needsAiRetry = true;
        });
      }
      _analysisTimer?.cancel();
      if (mounted && !_isSaving) {
        await _addMeal();
      }
    } finally {
      _analysisTimer?.cancel();
    }
  }

  Future<void> _retryAiFromEditor() async {
    final mealId = widget.mealId;
    if (mealId == null) return;
    setState(() => _isAnalyzing = true);
    try {
      await context.read<FoodAnalysisBlock>().retryAnalysisForMeal(mealId);
      await _loadMealData();
    } finally {
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
    if (_isSaving) return;
    _isSaving = true;
    _analysisTimer?.cancel();

    try {
      final protein = double.tryParse(_proteinController.text) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text) ?? 0.0;
      final fat = double.tryParse(_fatController.text) ?? 0.0;
      final calories = double.tryParse(_kcalController.text) ?? 0.0;

      if (!mounted) return;

      final String personID = _mealsPersonIdForQuery();

      final now = DateTime.now();
      final normalizedDate = DateTime(now.year, now.month, now.day);
      final dayDeterministicId = IDGen.generateDeterministicUuid(
        personID,
        DateFormat('yyyy-MM-dd').format(normalizedDate),
      );

      final String mealId = widget.mealId ?? IDGen.UUIDV7();

      final messenger = ScaffoldMessenger.maybeOf(context);

      if (widget.mealId != null) {
        context.read<HealthBlock>().skipCloudSyncForNextMealDerivedMetrics();
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
            isAnalyzing: Value(_isAnalyzing),
            needsAiRetry: Value(_needsAiRetry),
          ),
        );
      } else {
        await _healthMealDAO.insertMeal(
          MealsTableCompanion.insert(
            id: mealId,
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
            isAnalyzing: Value(_isAnalyzing),
            needsAiRetry: Value(_needsAiRetry),
          ),
        );
      }

      // Required for [HealthMealDAO.watchDaysWithMeals] (inner join on `days`).
      // Must run even when AI is running and the sheet is dismissed (no `mounted` skip).
      await _healthMealDAO.upsertDay(
        DaysTableCompanion.insert(
          id: dayDeterministicId,
          dayID: normalizedDate,
          caloriesOut: const Value(0),
          weight: const Value(0),
        ),
      );

      if (_isAnalyzing && mounted) {
        context.read<FoodAnalysisBlock>().analyzeAndSave(
          mealId: mealId,
          foodName: _foodController.text,
          image: _pickedImage,
          volume: _measuredVolume,
          distance: _dimensions?['length'],
          personId: personID,
        );

        messenger?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFD499D4),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "AI is analyzing your meal...",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A1024),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF322244)),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (mounted) {
        if (widget.isPopUp) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          context.go("/health/food/consume");
        }
      }
    } finally {
      _isSaving = false;
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

              if (widget.mealId != null && _needsAiRetry) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: obsidianCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.orange.withValues(alpha: 0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.nutri_ai_saved_retry_later,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isAnalyzing ? null : _retryAiFromEditor,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(l10n.nutri_ai_retry),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: premiumPink,
                            side: const BorderSide(color: obsidianBorder),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
            color: accent.withValues(alpha: 0.05),
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
          else if (_imagePath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: LocalFirstImage(
                localPath: _imagePath.startsWith('http') ? "" : _imagePath,
                remoteUrl: _imagePath.startsWith('http') ? _imagePath : "",
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                subFolder: 'meals',
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
                    color: accent.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to Capture or 3D Scan',
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.5),
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
              : (isClose ? Colors.red.withValues(alpha: 0.8) : Colors.black54),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          boxShadow: isScan
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.5),
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
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
          color: obsidianBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.7),
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
