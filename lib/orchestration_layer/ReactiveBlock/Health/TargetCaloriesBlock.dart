import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/Protocol/Health/TargetCaloriesProtocol.dart';

class TargetCaloriesBlock {
  final _state = signal<TargetCaloriesProtocol>(TargetCaloriesProtocol.empty());

  TargetCaloriesBlock([TargetCaloriesProtocol? initialProtocol]) {
    if (initialProtocol != null) {
      _state.value = initialProtocol;
    }
  }

  TargetCaloriesProtocol get state => _state.value;
  set state(TargetCaloriesProtocol value) => _state.value = value;

  // Computed Properties
  late final calculatedMacroCalories = computed(() {
    final s = _state.value;
    return (s.protein * 4) + (s.carbs * 4) + (s.fat * 9);
  });

  late final isCaloricMathCorrect = computed(() {
    return _state.value.calories == calculatedMacroCalories.value;
  });

  // Actions
  void setCalories(int value) {
    _state.value = _state.value.copyWith(calories: value);
  }

  void setProtein(int value) {
    _state.value = _state.value.copyWith(protein: value);
  }

  void setCarbs(int value) {
    _state.value = _state.value.copyWith(carbs: value);
  }

  void setFat(int value) {
    _state.value = _state.value.copyWith(fat: value);
  }

  void setProtocol(TargetCaloriesProtocol newProtocol) {
    _state.value = newProtocol;
  }

  void reset() {
    _state.value = TargetCaloriesProtocol.empty();
  }
}
