import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_chart/flutter_k_chart.dart';
import '../services/binance_service.dart';

class KLineScreen extends StatefulWidget {
  final String symbol;
  
  const KLineScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<KLineScreen> createState() => _KLineScreenState();
}

class _KLineScreenState extends State<KLineScreen> {
  List<KLineEntity> kLineData = [];
  String interval = '1m';
  final ChartStyle chartStyle = ChartStyle();
  final ChartColors chartColors = ChartColors();
  
  @override
  void initState() {
    super.initState();
    _loadKLineData();
  }

  Future<void> _loadKLineData() async {
    final binanceService = context.read<BinanceService>();
    final data = await binanceService.getKlineData(widget.symbol, interval);
    
    setState(() {
      kLineData = data.map((item) => KLineEntity.fromCustom(
        time: item['time'],
        open: item['open'],
        high: item['high'],
        low: item['low'],
        close: item['close'],
        vol: item['volume'],
        amount: 0.0,
      )).toList();
    });

    binanceService.connectToKlineStream(
      widget.symbol,
      interval,
      (newData) {
        setState(() {
          if (kLineData.isNotEmpty && 
              kLineData.last.time == newData['time']) {
            kLineData.last = KLineEntity.fromCustom(
              time: newData['time'],
              open: newData['open'],
              high: newData['high'],
              low: newData['low'],
              close: newData['close'],
              vol: newData['volume'],
              amount: 0.0,
            );
          } else {
            kLineData.add(KLineEntity.fromCustom(
              time: newData['time'],
              open: newData['open'],
              high: newData['high'],
              low: newData['low'],
              close: newData['close'],
              vol: newData['volume'],
              amount: 0.0,
            ));
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.symbol} K线图'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: interval,
              items: ['1m', '5m', '15m', '30m', '1h', '4h', '1d']
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    interval = value;
                    kLineData.clear();
                    _loadKLineData();
                  });
                }
              },
            ),
          ),
          Expanded(
            child: kLineData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : KChartWidget(
                    kLineData,
                    chartStyle,
                    chartColors,
                    isLine: false,
                    mainState: MainState.MA,
                    secondaryState: SecondaryState.MACD,
                    isTrendLine: false,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    context.read<BinanceService>().dispose();
    super.dispose();
  }
} 