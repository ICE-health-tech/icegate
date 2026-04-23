import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/ui_layer/animation_page/components/entry_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';

class FinanceOverviewPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceOverviewPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Main Billing Card
          Watch((context) {
            return _buildPremiumIceCard(context, financeBlock);
          }),
          const SizedBox(height: 24),

          // Summary Cards
          Watch((context) {
            return _buildSummaryCardRow(context, financeBlock);
          }),
          const SizedBox(height: 40),

          // Potential Chart Placeholder
          _buildAnalysisHeader(context),
          const SizedBox(height: 16),
          _buildEfficiencyPlaceholder(context),
          const SizedBox(height: 120), // Bottom space
        ],
      ),
    );
  }

  Widget _buildPremiumIceCard(BuildContext context, FinanceBlock block) {
    final burnRate = block.monthlyBurnRate.value;
    final totalSpent = block.monthlySpending.value;
    final progress = block.budgetUsagePercent.value / 100;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: EntryColors.glassBorder.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        EntryColors.financeYellow.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MONTHLY BURN",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          block.formatCurrency(burnRate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10, left: 4),
                          child: Text(
                            "/ mo",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _buildIceSubStat(
                            label: "ACTUAL SPENT",
                            value: block.formatCurrency(
                              totalSpent,
                              compact: true,
                            ),
                            icon: Icons.payments_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildIceSubStat(
                            label: "BUDGET HEALTH",
                            value: "${(progress * 100).toStringAsFixed(0)}%",
                            icon: Icons.shield_moon_rounded,
                            color: progress > 0.8
                                ? Colors.redAccent
                                : Colors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.9
                              ? Colors.redAccent
                              : EntryColors.financeYellow,
                        ),
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

  Widget _buildIceSubStat({
    required String label,
    required String value,
    required IconData icon,
    Color color = EntryColors.financeYellow,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white24, size: 10),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardRow(BuildContext context, FinanceBlock block) {
    return Row(
      children: [
        Expanded(
          child: _buildSimpleStatsCard(
            context,
            label: "SAVINGS",
            value: block.formatCurrency(
              block.totalSavings.value,
              compact: true,
            ),
            color: const Color(0xFF4CAF50),
            icon: Icons.savings_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSimpleStatsCard(
            context,
            label: "SPENDING",
            value: block.formatCurrency(
              block.monthlySpending.value,
              compact: true,
            ),
            color: const Color(0xFFF44336),
            icon: Icons.shopping_cart_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStatsCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader(BuildContext context) {
    return const Text(
      "FINANCIAL EFFICIENCY",
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildEfficiencyPlaceholder(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph_rounded, color: Colors.white12, size: 32),
            const SizedBox(height: 8),
            const Text(
              "ANALYSIS DATA PENDING",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
