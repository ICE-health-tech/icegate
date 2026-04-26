import 'dart:async';
import 'package:flutter/material.dart';

class MarketTicker extends StatefulWidget {
  final List<TickerItem> items;
  final Duration speed;

  const MarketTicker({
    super.key,
    required this.items,
    this.speed = const Duration(seconds: 30),
  });

  @override
  State<MarketTicker> createState() => _MarketTickerState();
}

class _MarketTickerState extends State<MarketTicker>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final remainingDistance = maxScroll - currentScroll;
    
    // Simple linear animation to the end
    _scrollController.animateTo(
      maxScroll,
      duration: widget.speed * (remainingDistance / maxScroll),
      curve: Curves.linear,
    ).then((_) {
      if (mounted) {
        _scrollController.jumpTo(0);
        _startScrolling();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: Colors.white10),
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        // Duplicate items for infinite feel
        itemBuilder: (context, index) {
          final item = widget.items[index % widget.items.length];
          return _buildTickerItem(item);
        },
      ),
    );
  }

  Widget _buildTickerItem(TickerItem item) {
    final isPositive = item.change >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.symbol,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.price,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: color,
                  size: 14,
                ),
                Text(
                  "${item.change.abs().toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: color,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TickerItem {
  final String symbol;
  final String price;
  final double change;

  TickerItem({
    required this.symbol,
    required this.price,
    required this.change,
  });
}
