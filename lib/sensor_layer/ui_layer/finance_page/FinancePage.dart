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
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:live_activities/live_activities.dart';

import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/transaction_builder_dialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceOverviewPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceTransactionsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceSubscriptionsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceStocksPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/subscription_manager.dart';

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

    return Watch((context) {
      final isBilling = financeBlock.activeTab.value == 2;
      return MainButton(
        type: "finance",
        destination: "/finance",
        size: size,
        backgroundColor: EntryColors.financeYellow.withValues(alpha: 0.9),
        iconColor: const Color(0xFF0D0D12),
        icon: Icons.add,
        mainFunction: () {
          if (isBilling) {
            showSubscriptionEditor(context, financeBlock);
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
      length: 4,
      vsync: this,
      initialIndex: _financeBlock.activeTab.peek().clamp(0, 3),
    );

    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      final newIndex = _tabController.index;
      if (_financeBlock.activeTab.peek() != newIndex) {
        untracked(() {
          _financeBlock.activeTab.value = newIndex;
        });
      }
      if (newIndex == 2) {
        unawaited(_financeBlock.refreshSubscriptions());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_financeBlock.refreshSubscriptions());
    });

    _disposeEffect = effect(() {
      final index = _financeBlock.activeTab.value.clamp(0, 3);
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
    switch (index) {
      case 0:
        return "OVERVIEW";
      case 1:
        return "HISTORY";
      case 2:
        return "BILLING";
      case 3:
        return "STOCKS";
      default:
        return "FINANCE";
    }
  }

  @override
  void dispose() {
    if (_activityId != null) _liveActivities.endActivity(_activityId!);
    _disposeEffect?.call();
    _scanController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeBlock = context.read<FinanceBlock>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // Deep Obsidian
      appBar: AppBar(
        toolbarHeight: 80, // Space for Dynamic Island, same as SocialPage
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Tactical Scanline
          _buildScanline(),

          SwipeablePage(
            onSwipe: () => context.pop(),
            direction: SwipeablePageDirection.leftToRight,
            child: Column(
              children: [
                const SizedBox(height: 120),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      FinanceOverviewPage(financeBlock: financeBlock),
                      FinanceTransactionsPage(financeBlock: financeBlock),
                      FinanceSubscriptionsPage(financeBlock: financeBlock),
                      FinanceStocksPage(financeBlock: financeBlock),
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
                            decoration: BoxDecoration(
                              color: EntryColors.financeYellow.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: EntryColors.financeYellow.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildCurrencyIndicator(
                                  "USD",
                                  !useVnd,
                                  EntryColors.financeYellow,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Icon(
                                    Icons.sync_alt_rounded,
                                    size: 14,
                                    color: EntryColors.financeYellow.withValues(alpha: 0.5),
                                  ),
                                ),
                                _buildCurrencyIndicator(
                                  "VND",
                                  useVnd,
                                  EntryColors.financeYellow,
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FinanceBlock block) {
    return Container(
      // Padding-top is now handled by AppBar, so we only need a small gap
      padding: const EdgeInsets.only(top: 80, bottom: 10, left: 24, right: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.maybePop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                "FINANCE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      TransactionBuilderDialog.show(
                        context,
                        financeBlock: block,
                      );
                    },
                    icon: const Icon(
                      Icons.add_box_rounded,
                      color: EntryColors.financeYellow,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Watch((context) {
                    final isSyncing = block.isSyncing.value;
                    return IconButton(
                      onPressed: isSyncing ? null : () => block.sync(),
                      icon: isSyncing
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: EntryColors.financeYellow.withValues(alpha: 0.5),
                              ),
                            )
                          : const Icon(
                              Icons.sync_rounded,
                              size: 18,
                              color: EntryColors.financeYellow,
                            ),
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: EntryColors.financeYellow,
            unselectedLabelColor: Colors.white24,
            dividerColor: Colors.transparent,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 3,
                color: EntryColors.financeYellow,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            tabs: [
              Tab(text: "OVERVIEW"),
              Tab(text: "HISTORY"),
              Tab(text: "BILLING"),
              Tab(text: "STOCKS"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlowSphere(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    );
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
  Widget _buildCurrencyIndicator(String label, bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          color: isActive ? Colors.black : color.withValues(alpha: 0.5),
        ),
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
              EntryColors.financeYellow.withValues(alpha: 0.03),
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
