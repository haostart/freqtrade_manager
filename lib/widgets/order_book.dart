import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';

class OrderBook extends StatelessWidget {
  const OrderBook({super.key});

  @override
  Widget build(BuildContext context) {
    final marketData = context.watch<MarketProvider>().marketData;
    final bids = (marketData['bids'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final asks = (marketData['asks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '订单簿',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // 表头
            Row(
              children: const [
                Expanded(child: Text('价格', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('数量', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('总额', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            
            const Divider(),
            
            // 卖单列表(倒序显示)
            ...asks.reversed.map((ask) => _buildOrderRow(
              ask['price'].toString(),
              ask['amount'].toString(),
              ask['total'].toString(),
              Colors.red,
            )),
            
            const Divider(thickness: 2),
            
            // 买单列表
            ...bids.map((bid) => _buildOrderRow(
              bid['price'].toString(),
              bid['amount'].toString(),
              bid['total'].toString(),
              Colors.green,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(String price, String amount, String total, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              price,
              style: TextStyle(color: color),
            ),
          ),
          Expanded(child: Text(amount)),
          Expanded(child: Text(total)),
        ],
      ),
    );
  }
} 