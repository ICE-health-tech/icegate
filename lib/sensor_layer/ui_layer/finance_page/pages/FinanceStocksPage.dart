import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/link_layer/finnace_services/stock_service.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/services/market_service.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/quick_save_sheet.dart';
import 'package:go_router/go_router.dart';

class FinanceStocksPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  FinanceStocksPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final txns = financeBlock.transactions.value;
      final stockTxns = txns.where((t) => t.category.toLowerCase() == 'stock').toList();
      
      // Group by ticker (description)
      final Map<String, List<TransactionData>> groupedStocks = {};
      for (final t in stockTxns) {
        final ticker = t.description?.toUpperCase() ?? 'UNKNOWN';
        groupedStocks.putIfAbsent(ticker, () => []).add(t);
      }

      final tickers = groupedStocks.keys.toList();

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  QuickSaveSheet.show(context, financeBlock);
                },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.savings_rounded, color: Colors.greenAccent.withValues(alpha: 0.95), size: 26),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Log savings (opens quick save)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.35)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStockSummary(context, groupedStocks),
            const SizedBox(height: 32),
            _buildMarketPulse(context),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "YOUR SAVINGS",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    "${tickers.length} ASSETS",
                    style: const TextStyle(
                      color: EntryColors.iceCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (tickers.isEmpty)
              _buildEmptyState(context)
            else
              ...tickers.map((ticker) => _buildStockTile(context, ticker, groupedStocks[ticker]!)),
            const SizedBox(height: 32),
            _buildWatchlistHeader(),
            const SizedBox(height: 16),
            _buildWatchlist(context),
            const SizedBox(height: 120),
          ],
        ),
      );
    });
  }

  Widget _buildWatchlistHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        "WATCHLIST",
        style: TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildWatchlist(BuildContext context) {
    final List<String> importantStocks = [
      'VNM', 'FPT', 'VCB', 'VIC', 'VHM', 'HPG', 'GAS', 'MSN', 'MWG', 'SSI'
    ];

    return Column(
      children: importantStocks.map((ticker) => _buildStockTile(context, ticker, [])).toList(),
    );
  }

  Widget _buildStockSummary(BuildContext context, Map<String, List<TransactionData>> grouped) {
    double totalInvested = 0;
    for (final list in grouped.values) {
      for (final t in list) {
        if (t.type == 'expense' || t.type == 'investment') {
          totalInvested += t.amount;
        } else if (t.type == 'income') {
          totalInvested -= t.amount; // Selling
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EntryColors.iceCyan.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: EntryColors.iceCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOTAL EQUITY",
            style: TextStyle(
              color: EntryColors.iceCyan,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            financeBlock.formatCurrency(totalInvested),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat("ASSETS", grouped.length.toString()),
              const SizedBox(width: 24),
              _buildMiniStat("STATUS", "TRACKING", color: Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color color = Colors.white54}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildStockTile(BuildContext context, String ticker, List<TransactionData> txns) {
    double invested = 0;
    double grossPurchases = 0;
    for (final t in txns) {
      if (t.type == 'expense' || t.type == 'investment') {
        invested += t.amount;
        grossPurchases += t.amount;
      } else if (t.type == 'income') {
        invested -= t.amount;
      }
    }

    final String statusSubtitle;
    if (invested > 0) {
      statusSubtitle = 'Invested';
    } else if (grossPurchases > 0) {
      // Net position is flat or closed, but buys existed (e.g. sold entire stake).
      statusSubtitle = 'Position closed';
    } else {
      statusSubtitle = 'No buys logged';
    }

    final stockService = StockService();
    final displayName = stockService.getStockName(ticker);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () => context.push('/finance/stock/$ticker'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EntryColors.iceCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.show_chart_rounded, color: EntryColors.iceCyan, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ticker,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        if (displayName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              "($displayName)",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Text(
                      "From your transactions",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    invested > 0
                        ? financeBlock.formatCurrency(invested)
                        : "—",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  Text(
                    statusSubtitle,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white12, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketPulse(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "MARKET PULSE",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MarketService.fetchGoldPrices(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final price = data != null && data.isNotEmpty ? data.first['sjc'][0]['sell_price'].toString() : "---";
                  return _buildPulseCard("GOLD", "SJC", price, Icons.auto_awesome, Colors.amber);
                }
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MarketService.fetchIndexHistorical("VNINDEX"),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final price = data != null && data.isNotEmpty ? data.last['close'].toString() : "---";
                  return _buildPulseCard("VNINDEX", "INDEX", price, Icons.trending_up, Colors.blue);
                }
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MarketService.fetchIndexHistorical("VN30"),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final price = data != null && data.isNotEmpty ? data.last['close'].toString() : "---";
                  return _buildPulseCard("VN30", "INDEX", price, Icons.layers_outlined, Colors.indigo);
                }
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MarketService.fetchForexHistorical(symbol: "USDVND"),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final price = data != null && data.isNotEmpty ? data.last['close'].toString() : "---";
                  return _buildPulseCard("USDVND", "FOREX", price, Icons.currency_exchange, Colors.green);
                }
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: MarketService.fetchCryptoHistorical(symbol: "BTC"),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final price = data != null && data.isNotEmpty ? data.last['close'].toString() : "---";
                  return _buildPulseCard("BTC", "CRYPTO", price, Icons.currency_bitcoin, Colors.orange);
                }
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPulseCard(String symbol, String type, String price, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 14),
              Text(
                type,
                style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          Text(
            symbol,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            price == "---" ? "Fetching..." : price,
            style: TextStyle(
              color: price == "---" ? Colors.white24 : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono'
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white.withValues(alpha: 0.1), size: 40),
          const SizedBox(height: 16),
          const Text(
            "NO SAVINGS TRACKED",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add transactions with category Saving",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
