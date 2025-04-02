import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';
import '../services/api_service.dart';

class TradePanel extends StatefulWidget {
  final String pair;
  
  const TradePanel({
    super.key,
    required this.pair,
  });

  @override
  State<TradePanel> createState() => _TradePanelState();
}

class _TradePanelState extends State<TradePanel> {
  final _priceController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedOrderType = 'limit';
  String _selectedSide = 'long';

  @override
  void dispose() {
    _priceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _placeOrder(BuildContext context) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      final price = double.parse(_priceController.text);
      final amount = double.parse(_amountController.text);

      await apiService.placeOrder(
        pair: widget.pair,
        side: _selectedSide,
        price: price,
        amount: amount,
        orderType: _selectedOrderType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下单成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下单失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketData = context.watch<MarketProvider>().marketData;
    final currentPrice = marketData['price'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pair,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // 交易方向选择
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'long',
                  label: Text('做多'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'short',
                  label: Text('做空'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_selectedSide},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedSide = selection.first;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // 订单类型选择
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'limit',
                  label: Text('限价单'),
                ),
                ButtonSegment(
                  value: 'market',
                  label: Text('市价单'),
                ),
              ],
              selected: {_selectedOrderType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedOrderType = selection.first;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // 价格输入
            if (_selectedOrderType == 'limit')
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: '价格',
                  suffixText: '当前: $currentPrice',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              
            const SizedBox(height: 16),
            
            // 数量输入
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '数量',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            const SizedBox(height: 24),
            
            // 下单按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _placeOrder(context),
                child: Text(
                  _selectedSide == 'long' ? '买入' : '卖出',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 