import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:live_activities/live_activities.dart';

import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/QuickSaveSheet.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/finance_form/AddAccountDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/TransactionBuilderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceOverviewPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceDailyPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceSubscriptionsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceSavingsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceJobPositionsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/JobPositionManager.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/SubscriptionManager.dart';

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
      case 'human_capital':
        return l10n.finance_cat_human_capital;
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
      case 'impulse':
        return l10n.finance_cat_impulse;
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

    return Watch((context) {
      final tab = financeBlock.activeTab.value;
      return MainButton(
        type: "finance",
        destination: "/finance",
        size: size,
        backgroundColor: EntryColors.financeSilverAccent.withValues(alpha: 0.92),
        iconColor: EntryColors.deepGlacier,
        icon: Icons.add,
        mainFunction: () {
          if (tab == 0) {
            AddAccountDialog.show(context);
          } else if (tab == 1) {
            TransactionBuilderDialog.show(context, financeBlock: financeBlock);
          } else if (tab == 2) {
            showSubscriptionEditor(context, financeBlock);
          } else if (tab == 3) {
            QuickSaveSheet.show(context, financeBlock);
          } else if (tab == 4) {
            showJobPositionEditor(context, financeBlock);
          } else {
            TransactionBuilderDialog.show(context, financeBlock: financeBlock);
          }
        },
        onSwipeUp: () => WidgetNavigatorAction.smartPop(context),
        onSwipeRight: () => WidgetNavigatorAction.smartPop(context),
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
    });
  }

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late FinanceBlock _financeBlock;
  final _liveActivities = LiveActivities();
  String? _activityId;
  EffectCleanup? _disposeEffect;

  @override
  void initState() {
    super.initState();
    _financeBlock = context.read<FinanceBlock>();

    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _financeBlock.activeTab.peek().clamp(0, 4),
    );

    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      final newIndex = _tabController.index;
      if (_financeBlock.activeTab.peek() != newIndex) {
        untracked(() {
          _financeBlock.activeTab.value = newIndex;
        });
      }
      if (newIndex == 0) {
        unawaited(_financeBlock.refreshRecurringIncomes());
      }
      if (newIndex == 2) {
        unawaited(_financeBlock.refreshSubscriptions());
      }
      if (newIndex == 4) {
        unawaited(_financeBlock.refreshJobPositions());
        unawaited(_financeBlock.refreshRecurringIncomes());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_financeBlock.refreshSubscriptions());
    });

    _disposeEffect = effect(() {
      final index = _financeBlock.activeTab.value.clamp(0, 4);
      if (mounted) _updateLiveActivity(context, index);
      if (_tabController.index != index) {
        if (mounted) _tabController.animateTo(index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move activity creation here to safely access AppLocalizations
    if (_activityId == null) {
      _createLiveActivity();
    }
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
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.finance_tab_overview;
      case 1:
        return l10n.finance_tab_daily;
      case 2:
        return l10n.finance_tab_billing;
      case 3:
        return l10n.finance_tab_saving;
      case 4:
        return l10n.finance_tab_career;
      default:
        return l10n.finance.toUpperCase();
    }
  }

  @override
  void dispose() {
    if (_activityId != null) _liveActivities.endActivity(_activityId!);
    _disposeEffect?.call();
    _tabController.dispose();
    super.dispose();
  }

  /// Clears [MainShell]'s Dynamic Island (SafeArea + 54px bar + 2px pad).
  static double _islandTopInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 56 + 8;

  @override
  Widget build(BuildContext context) {
    final financeBlock = context.read<FinanceBlock>();
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = _islandTopInset(context);

    return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SwipeablePage(
          onSwipe: () => context.pop(),
          direction: SwipeablePageDirection.leftToRight,
          child: Column(
            children: [
              SizedBox(height: topInset),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    FinanceOverviewPage(financeBlock: financeBlock),
                    FinanceDailyPage(financeBlock: financeBlock),
                    FinanceSubscriptionsPage(financeBlock: financeBlock),
                    FinanceSavingsPage(financeBlock: financeBlock),
                    FinanceJobPositionsPage(financeBlock: financeBlock),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20, right: 24),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Watch((context) {
                      final useVnd = financeBlock.useVnd.value;
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final cs = Theme.of(context).colorScheme;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          financeBlock.toggleCurrency();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration:
                              FinanceSurface.panel(cs, isDark: isDark, radius: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCurrencyIndicator(
                                "USD",
                                !useVnd,
                                isDark: isDark,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Icon(
                                  Icons.sync_alt_rounded,
                                  size: 14,
                                  color: FinanceSurface.mutedInk(isDark: isDark),
                                ),
                              ),
                              _buildCurrencyIndicator(
                                "VND",
                                useVnd,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildCurrencyIndicator(
    String label,
    bool isActive, {
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FinanceSurface.currencyPillBackground(
          isDark: isDark,
          active: isActive,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          color: FinanceSurface.currencyPillForeground(
            isDark: isDark,
            active: isActive,
          ),
        ),
      ),
    );
  }
}
