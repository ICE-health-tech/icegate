import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/animation_page/components/entry_constants.dart';
import 'package:live_activities/live_activities.dart';
import 'package:flutter/foundation.dart';

import 'package:ice_gate/ui_layer/finance_page/widgets/transaction_builder_dialog.dart';
import 'package:ice_gate/ui_layer/finance_page/pages/finance_overview_page.dart';
import 'package:ice_gate/ui_layer/finance_page/pages/finance_transactions_page.dart';
import 'package:ice_gate/ui_layer/finance_page/pages/finance_subscriptions_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  static String getCategoryName(AppLocalizations l10n, String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return l10n.finance_cat_food;
      case 'coffee':
        return l10n.finance_cat_coffee;
      case 'transport':
        return l10n.finance_cat_transport;
      case 'software':
        return l10n.finance_cat_software;
      case 'shopping':
        return l10n.finance_cat_shopping;
      case 'bills':
        return l10n.finance_cat_bills;
      case 'rent':
        return l10n.finance_cat_rent;
      case 'subscriptions':
        return l10n.finance_cat_subscriptions;
      case 'entertainment':
        return l10n.finance_cat_entertainment;
      case 'health':
        return l10n.finance_cat_health;
      case 'education':
        return l10n.finance_cat_education;
      case 'investing':
        return l10n.finance_cat_investing;
      case 'salary':
        return l10n.finance_cat_salary;
      case 'freelance':
        return l10n.finance_cat_freelance;
      case 'investment':
        return l10n.finance_cat_investment;
      case 'gift':
        return l10n.finance_cat_gift;
      case 'bonus':
        return l10n.finance_cat_bonus;
      case 'emergency':
        return l10n.finance_cat_emergency;
      case 'goal':
        return l10n.finance_cat_goal;
      case 'retirement':
        return l10n.finance_cat_retirement;
      case 'crypto':
        return l10n.finance_cat_crypto;
      case 'stock':
        return l10n.finance_cat_stock;
      case 'real estate':
        return l10n.finance_cat_real_estate;
      default:
        return l10n.finance_cat_general;
    }
  }

  static Widget icon(BuildContext context, {double? size}) {
    final l10n = AppLocalizations.of(context)!;
    final financeBlock = context.read<FinanceBlock>();

    return MainButton(
      type: "finance",
      destination: "/finance",
      size: size,
      icon: Icons.add,
      mainFunction: () {
        TransactionBuilderDialog.show(context, financeBlock: financeBlock);
      },
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      subButtons: [
        SubButton(
          icon: Icons.savings_rounded,
          backgroundColor: Colors.green,
          label: l10n.finance_label_save,
          tooltip: l10n.finance_tooltip_add_savings,
          onPressed: () => TransactionBuilderDialog.show(
            context,
            preferredType: 'savings',
            financeBlock: financeBlock,
          ),
        ),
        SubButton(
          icon: Icons.shopping_cart_rounded,
          backgroundColor: Colors.red,
          label: l10n.finance_label_spend,
          tooltip: l10n.finance_tooltip_add_expense,
          onPressed: () => TransactionBuilderDialog.show(
            context,
            preferredType: 'expense',
            financeBlock: financeBlock,
          ),
        ),
        SubButton(
          icon: Icons.attach_money_rounded,
          backgroundColor: Colors.blue,
          label: l10n.finance_label_income,
          tooltip: l10n.finance_tooltip_add_income,
          onPressed: () => TransactionBuilderDialog.show(
            context,
            preferredType: 'income',
            financeBlock: financeBlock,
          ),
        ),
      ],
    );
  }

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late TabController _tabController;
  late FinanceBlock _financeBlock;
  final _liveActivities = LiveActivities();
  String? _activityId;
  EffectCleanup? _disposeEffect;

  @override
  void initState() {
    super.initState();
    _financeBlock = context.read<FinanceBlock>();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _financeBlock.activeTab.peek().clamp(0, 2),
    );

    // Sync signal -> tab
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      final newIndex = _tabController.index;
      if (_financeBlock.activeTab.peek() != newIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            untracked(() {
              _financeBlock.activeTab.value = newIndex;
            });
          }
        });
      }
    });

    _createLiveActivity();

    _disposeEffect = effect(() {
      final rawIndex = _financeBlock.activeTab.value;
      final index = rawIndex.clamp(0, 2);

      if (mounted) {
        _updateLiveActivity(context, index);
      }

      if (_tabController.index != index) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tabController.animateTo(index);
          }
        });
      }
    });
  }

  Future<void> _createLiveActivity() async {
    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _activityId = await _liveActivities
          .createActivity('group.duylong.art.iceshield', {
            'title': l10n.scoring_finance,
            'songName': _getTabName(context, _tabController.index),
            'artist': "ICE GATE",
            'cover': "finance_cover",
            'progress': 0.0,
          });
    } catch (e) {
      debugPrint("Finance Live Activity Creation Error: $e");
    }
  }

  void _updateLiveActivity(BuildContext context, int index) {
    if (_activityId != null) {
      try {
        final l10n = AppLocalizations.of(context)!;
        _liveActivities.updateActivity(_activityId!, {
          'title': l10n.scoring_finance,
          'songName': _getTabName(context, index),
          'artist': "ICE GATE",
          'cover': "finance_cover",
          'progress': 0.0,
        });
      } catch (e) {
        debugPrint("Finance Live Activity Update Error: $e");
      }
    }
  }

  String _getTabName(BuildContext context, int index) {
    switch (index) {
      case 0:
        return "OVERVIEW";
      case 1:
        return "HISTORY";
      case 2:
        return "BILLING";
      default:
        return "FINANCE";
    }
  }

  @override
  void dispose() {
    if (_activityId != null) {
      _liveActivities.endActivity(_activityId!);
    }
    _disposeEffect?.call();
    _scanController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildScanline() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinePainter(progress: _scanController.value),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeBlock = context.read<FinanceBlock>();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(gradient: EntryColors.obsidianGradient),
      child: Stack(
        children: [
          _buildScanline(),
          SwipeablePage(
            onSwipe: () => Navigator.maybePop(context),
            direction: SwipeablePageDirection.leftToRight,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                toolbarHeight: 60,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Watch((context) {
                    final useVnd = financeBlock.useVnd.value;
                    return IconButton(
                      onPressed: () => financeBlock.toggleCurrency(),
                      icon: Text(
                        useVnd ? 'VND' : 'USD',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: EntryColors.arcticSilver,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  FinanceOverviewPage(financeBlock: financeBlock),
                  FinanceTransactionsPage(financeBlock: financeBlock),
                  FinanceSubscriptionsPage(financeBlock: financeBlock),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  _ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              EntryColors.financeYellow.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromLTWH(0, (progress * size.height) - 50, size.width, 100),
          );

    canvas.drawRect(
      Rect.fromLTWH(0, (progress * size.height) - 50, size.width, 100),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
