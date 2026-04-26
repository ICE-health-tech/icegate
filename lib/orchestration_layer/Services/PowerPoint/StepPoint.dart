
class StepPoint {
  static double calculateBonus(int steps, double calories) {
    double bonus = 0;
    if (steps > 100) {
      bonus += 1;
    }
    if (calories < 1500) {
      bonus += 10;
    }
    return bonus;
  }
}
