import 'dart:math';

/// Quantitative utility class for financial performance metrics.
class QuantMath {
  /// Calculates the Sharpe Ratio of a series of returns.
  /// [returns]: A list of percentage returns (e.g., 0.01 for 1%).
  /// [riskFreeRate]: The annualized risk-free rate (e.g., 0.04 for 4%).
  /// Returns the annualized Sharpe Ratio.
  static double calculateSharpeRatio(List<double> returns, {double riskFreeRate = 0.04}) {
    if (returns.length < 2) return 0.0;
    
    // Adjust risk-free rate to the period of the returns (assuming daily returns)
    final dailyRiskFreeRate = pow(1 + riskFreeRate, 1 / 365) - 1;
    
    final meanReturn = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((x) => pow(x - meanReturn, 2)).reduce((a, b) => a + b) / (returns.length - 1);
    final stdDev = sqrt(variance);
    
    if (stdDev == 0) return 0.0;
    
    final excessReturn = meanReturn - dailyRiskFreeRate;
    final dailySharpe = excessReturn / stdDev;
    
    // Annualize (sqrt of 252 trading days or 365 calendar days)
    return dailySharpe * sqrt(365);
  }

  /// Calculates the current Drawdown from the All-Time High (ATH).
  /// [currentValue]: Current net worth.
  /// [athValue]: Highest recorded net worth.
  static double calculateDrawdown(double currentValue, double athValue) {
    if (athValue <= 0 || currentValue >= athValue) return 0.0;
    return (athValue - currentValue) / athValue;
  }

  /// Calculates the Daily Delta (percent change).
  /// [currentValue]: Current net worth.
  /// [previousValue]: Previous day's closing net worth.
  static double calculateDelta(double currentValue, double previousValue) {
    if (previousValue <= 0) return 0.0;
    return (currentValue - previousValue) / previousValue;
  }
}
