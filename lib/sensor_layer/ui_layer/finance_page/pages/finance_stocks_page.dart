import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/link_layer/finnace_services/stock_service.dart';
import 'package:ice_gate/sensor_layer/ui_layer/stock_page/models/stock_data.dart';
import 'package:go_router/go_router.dart';

class FinanceStocksPage extends StatelessWidget {
  final FinanceBlock financeBlock;
  final _stockService = StockService();

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
            _buildStockSummary(context, groupedStocks),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "YOUR HOLDINGS",
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
            EntryColors.iceCyan.withOpacity(0.1),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: EntryColors.iceCyan.withOpacity(0.2)),
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
    for (final t in txns) {
      if (t.type == 'expense' || t.type == 'investment') invested += t.amount;
      else if (t.type == 'income') invested -= t.amount;
    }

    return FutureBuilder<StockFullInfo?>(
      future: _stockService.fetchAllStockInfo(ticker),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final priceData = info?.price;
        final bool isLoss = (priceData?.change ?? 0) < 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: priceData != null 
                ? (isLoss ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2))
                : Colors.white.withOpacity(0.05)
            ),
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
                      color: EntryColors.iceCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: FutureBuilder<StockHistoricalData?>(
                        future: _stockService.fetchHistoricalData(ticker, startDate: DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T')[0]),
                        builder: (context, histSnapshot) {
                          final hist = histSnapshot.data;
                          if (hist == null || hist.data.isEmpty) {
                            return const Icon(Icons.show_chart_rounded, color: EntryColors.iceCyan, size: 24);
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: hist.data.length.toDouble() - 1,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: hist.data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.close ?? 0)).toList(),
                                    isCurved: true,
                                    color: isLoss ? Colors.redAccent : Colors.greenAccent,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: (isLoss ? Colors.redAccent : Colors.greenAccent).withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
                            if (_stockService.getStockName(ticker).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  "(${_stockService.getStockName(ticker)})",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (priceData != null)
                          Text(
                            "${priceData.changePercent > 0 ? '+' : ''}${priceData.changePercent.toStringAsFixed(2)}%",
                            style: TextStyle(
                              color: isLoss ? Colors.redAccent : Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const Text(
                            "Market Asset",
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceData != null 
                          ? financeBlock.formatCurrency(priceData.price / 24000) 
                          : (snapshot.connectionState == ConnectionState.waiting 
                              ? "Loading..." 
                              : (invested > 0 ? financeBlock.formatCurrency(invested) : "Fetch Error")),
                        style: TextStyle(
                          color: priceData != null ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                      Text(
                        priceData != null 
                          ? "Current Price" 
                          : (invested > 0 ? "Invested (Offline)" : "No Data"),
                        style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white.withOpacity(0.1), size: 40),
          const SizedBox(height: 16),
          const Text(
            "NO STOCKS TRACKED",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add transactions with category 'Stock'",
            style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
