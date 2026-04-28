import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:ice_gate/link_layer/finnace_services/stock_service.dart';
import 'package:ice_gate/sensor_layer/ui_layer/stock_page/models/stock_data.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';

class StockPage extends StatefulWidget {
  final String symbol;

  const StockPage({super.key, required this.symbol});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _stockService = StockService();
  
  late final _stockInfo = signal<StockFullInfo?>(null);
  late final _historicalData = signal<StockHistoricalData?>(null);
  late final _isLoading = signal<bool>(true);
  late final _timeRange = signal<String>('1M');
  late final _error = signal<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final info = await _stockService.fetchAllStockInfo(widget.symbol);
      final history = await _stockService.fetchHistoricalData(widget.symbol, startDate: _getStartDateForRange(_timeRange.value));
      
      _stockInfo.value = info;
      _historicalData.value = history;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  String _getStartDateForRange(String range) {
    final now = DateTime.now();
    switch (range) {
      case '1W': return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
      case '1M': return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
      case '3M': return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 90)));
      case '1Y': return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 365)));
      default: return '2024-01-01';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      if (_isLoading.value) {
        return const Scaffold(
          backgroundColor: EntryColors.glacierBase,
          body: Center(child: CircularProgressIndicator(color: EntryColors.iceCyan)),
        );
      }

      if (_error.value != null) {
        return Scaffold(
          backgroundColor: EntryColors.glacierBase,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(child: Text('Error: ${_error.value}', style: const TextStyle(color: Colors.red))),
        );
      }

      final info = _stockInfo.value;
      if (info == null) return const Scaffold();

      return Scaffold(
        backgroundColor: EntryColors.glacierBase,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Text(
                widget.symbol.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                "(${StockService().getStockName(widget.symbol)})",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.star_border, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(info.price),
              const SizedBox(height: 30),
              _buildChartSection(),
              const SizedBox(height: 30),
              _buildStatsGrid(info.price),
              const SizedBox(height: 30),
              _buildOverviewSection(info.company),
              const SizedBox(height: 100), // Space for trade button
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildTradeButton(),
      );
    });
  }

  Widget _buildHeader(StockPrice price) {
    final isPositive = price.change >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(price.price * 1000),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: color, size: 20),
            const SizedBox(width: 5),
            Text(
              '${isPositive ? '+' : ''}${price.change} (${price.changePercent}%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Today',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['1W', '1M', '3M', '1Y', 'ALL'].map((range) {
            final isSelected = _timeRange.value == range;
            return GestureDetector(
              onTap: () {
                _timeRange.value = range;
                _loadAllData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? EntryColors.iceCyan.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? EntryColors.iceCyan : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  range,
                  style: TextStyle(
                    color: isSelected ? EntryColors.iceCyan : Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: _buildChart(),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final history = _historicalData.value;
    if (history == null || history.data.isEmpty) {
      return const Center(child: Text('No historical data available', style: TextStyle(color: Colors.white54)));
    }

    final spots = history.data.asMap().entries.where((e) => e.value.close != null).map((e) {
      return FlSpot(e.key.toDouble(), e.value.close!);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: EntryColors.iceCyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  EntryColors.iceCyan.withValues(alpha: 0.3),
                  EntryColors.iceCyan.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(StockPrice price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('High', price.high?.toString() ?? 'N/A'),
              _buildStatItem('Low', price.low?.toString() ?? 'N/A'),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Volume', _formatVolume(price.volume)),
              _buildStatItem('Time', price.time ?? '--:--'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) return '${(volume / 1000000).toStringAsFixed(2)}M';
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}K';
    return volume.toString();
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildOverviewSection(StockOverview company) {
    if (company.overview.isEmpty) return const SizedBox();
    
    final overview = company.overview.first;
    final description = overview.businessModel ?? overview.history ?? 'No description available.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About Company',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Text(
          description,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTradeButton() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: EntryColors.iceCyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          shadowColor: EntryColors.iceCyan.withValues(alpha: 0.5),
        ),
        child: const Text(
          'TRADE NOW',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
        ),
      ),
    );
  }
}
