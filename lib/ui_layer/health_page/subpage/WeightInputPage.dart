import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/UIResponsiveManager.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';

class WeightInputPage extends StatefulWidget {
  final DateTime? initialDate;
  const WeightInputPage({super.key, this.initialDate});

  @override
  State<WeightInputPage> createState() => _WeightInputPageState();

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "weight_log",
      destination: "/health/weight/log",
            onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      size: size,
      icon: Icons.add,
      mainFunction: () {
        // print("HI");
      },
    );
  }
}

class _WeightInputPageState extends State<WeightInputPage> {
  final TextEditingController _weightController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;

    final healthBlock = context.read<HealthBlock>();
    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    if (personId.isNotEmpty) {
      await healthBlock.updateWeight(weight, date: _selectedDate);
      if (mounted) {
        WidgetNavigatorAction.smartPop(context);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.purpleAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final padding = UIResponsiveManager.padding(context);
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
        title: const Text('Log Weight', style: TextStyle(fontWeight: FontWeight.w900)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Big Weight Input
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(
                  fontSize: UIResponsiveManager.responsiveFontScale(context) * 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "0.0",
                  suffixText: "kg",
                  suffixStyle: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.3),
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 40),
              
              // Date Selection (matches FoodInputPage TextField style but interactive)
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(buttonRadius),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: UIResponsiveManager.inputFieldSpacing(context, factor: 1.5),
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(buttonRadius),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: iconSize, color: Colors.purpleAccent),
                      const SizedBox(width: 16),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: UIResponsiveManager.responsiveFontScale(context) * 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_rounded, size: 16, color: Colors.white24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // The "SAVE RECORD" Button (Exact match to FoodInputPage)
              ElevatedButton(
                onPressed: _saveWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: UIResponsiveManager.inputFieldSpacing(context, factor: 1.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonRadius + 4),
                  ),
                  elevation: UIResponsiveManager.cardElevation(context),
                  shadowColor: Colors.purpleAccent.withValues(alpha: 0.4),
                ),
                child: Text(
                  'SAVE RECORD',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: UIResponsiveManager.responsiveFontScale(context) * 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
