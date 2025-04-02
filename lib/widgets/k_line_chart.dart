import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class KLineChart extends StatefulWidget {
  final List<Map<String, dynamic>>? trades;
  const KLineChart({super.key, this.trades});

  @override
  State<KLineChart> createState() => KLineChartState();
}

class KLineChartState extends State<KLineChart> {
  Future<List<Map<String, dynamic>>>? _kLineData;
  double _minX = 0;
  double _maxX = 0;
  final int _visibleSpots = 48; // 显示48小时的数据
  bool _initialized = false; // 添加初始化标志
  bool _isMobile = false;  // 添加一个字段来存储是否为移动端

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 使用初始化标志来控制只初始化一次
    if (!_initialized) {
      _initialized = true;
      _isMobile = MediaQuery.of(context).size.width < 600;  // 在这里判断并保存
      _kLineData = _fetchKLineData();
      if (_isMobile) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  @override
  void dispose() {
    // 只在移动端恢复竖屏
    if (_isMobile) {  // 使用保存的值
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchKLineData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // 增加超时时间到60秒
      return await apiService.getKLineData(pair: 'BTCUSDT', interval: '1h')
          .timeout(const Duration(seconds: 60), onTimeout: () {
        throw TimeoutException(AppLocalizations.of(context)!.getKLineDataTimeout);
      });
    } catch (e) {
      print('获取K线数据失败: $e');
      rethrow;
    }
  }

  void _updateVisibleData(List<FlSpot> spots) {
    if (spots.isEmpty) return;

    // 初始显示最后48个数据点
    _maxX = spots.last.x;
    _minX = spots[spots.length > _visibleSpots ? spots.length - _visibleSpots : 0].x;
  }

  void _onPanUpdate(DragUpdateDetails details, List<FlSpot> spots) {
    if (spots.isEmpty) return;

    final double dragAmount = -details.delta.dx * 3600000; // 1小时的毫秒数
    final double newMinX = _minX + dragAmount;
    final double newMaxX = _maxX + dragAmount;

    // 确保不会滑出数据范围
    if (newMinX >= spots.first.x && newMaxX <= spots.last.x) {
      setState(() {
        _minX = newMinX;
        _maxX = newMaxX;
      });
    }
  }

  String _formatDateTime(double value) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    // 如果是0点，显示日期
    if (dateTime.hour == 0) {
      return DateFormat('MM-dd').format(dateTime); // 显示日期
    }
    return DateFormat('HH:mm').format(dateTime); // 其他时间显示小时
  }

  String _formatPrice(double value) {
    return NumberFormat('#,##0.00').format(value);
  }

  void refreshData() {
    setState(() {
      _kLineData = _fetchKLineData(); // 重新获取数据
    });
  }

  List<FlSpot> _getTradeSpots() {
    if (widget.trades == null) return [];
    
    List<FlSpot> tradeSpots = [];
    for (var trade in widget.trades!) {
      final time = trade['openTime'] != null 
          ? DateTime.parse(trade['openTime']).millisecondsSinceEpoch.toDouble() 
          : 0.0; // 使用默认值或处理 null 的情况
      final price = trade['openPrice'] != null 
          ? double.parse(trade['openPrice']) 
          : 0.0; // 处理 null 的情况
      tradeSpots.add(FlSpot(time, price));
    }
    return tradeSpots;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isMobile = size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: isMobile ? (isLandscape ? size.width : size.height) : size.width,
        height: isMobile ? (isLandscape ? size.height : size.width) : size.height,
        child: Stack(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _kLineData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Text(l10n.loading));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('${l10n.getKLineDataFailed}${snapshot.error}'));
                }

                final kLineData = snapshot.data;
                if (kLineData == null || kLineData.isEmpty) {
                  return Center(child: Text(l10n.noKLineData));
                }

                List<FlSpot> spots = [];
                for (var item in kLineData) {
                  final time = DateTime.fromMillisecondsSinceEpoch(item['time']);
                  final close = double.parse(item['close']);
                  spots.add(FlSpot(time.millisecondsSinceEpoch.toDouble(), close));
                }

                // 获取订单标记点
                final tradeSpots = _getTradeSpots();

                // 始化可见数据范围
                if (_minX == 0 && _maxX == 0) {
                  _updateVisibleData(spots);
                }

                // 计算当前可见范围内的最大最小值
                double minY = double.infinity;
                double maxY = double.negativeInfinity;
                for (var spot in spots) {
                  if (spot.x >= _minX && spot.x <= _maxX) {
                    if (spot.y < minY) minY = spot.y;
                    if (spot.y > maxY) maxY = spot.y;
                  }
                }
                double interval = (maxY - minY) / 6;

                return GestureDetector(
                  onPanUpdate: (details) => _onPanUpdate(details, spots),
                  child: Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        // 鼠标滚轮滚动时的处理
                        final double dragAmount = pointerSignal.scrollDelta.dx != 0 
                            ? pointerSignal.scrollDelta.dx * 3600000 
                            : pointerSignal.scrollDelta.dy * 3600000;
                        
                        final double newMinX = _minX + dragAmount;
                        final double newMaxX = _maxX + dragAmount;
                        
                        // 确保不会滑出数据范围
                        if (newMinX >= spots.first.x && newMaxX <= spots.last.x) {
                          setState(() {
                            _minX = newMinX;
                            _maxX = newMaxX;
                          });
                        }
                      }
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: LineChart(
                          LineChartData(
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: const Color(0xFF000000).withAlpha(204),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                tooltipMargin: 8,
                                maxContentWidth: 150,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                tooltipBorder: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final time = _formatDateTime(spot.x);
                                    final price = _formatPrice(spot.y);
                                    return LineTooltipItem(
                                      '$time\n$price',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                              handleBuiltInTouches: true,
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 65,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        _formatPrice(value),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 3600000 * 2, // 每2小时显示一个刻度
                                  getTitlesWidget: (value, meta) {
                                    if (meta.min == value) return const SizedBox.shrink();
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 10,
                                      child: Text(
                                        _formatDateTime(value), // 根据条件显示日期或小时
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: interval,
                              verticalInterval: 3600000,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.15),
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.15),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                // 在这里添加订单位置的水平线
                                for (var spot in tradeSpots)
                                  if (spot.x >= _minX && spot.x <= _maxX)
                                    HorizontalLine(
                                      y: spot.y,
                                      color: Colors.grey.withOpacity(0.5),
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    ),
                              ],
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: const Color.fromARGB(255, 255, 183, 0),
                                barWidth: 2,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color.fromARGB(255, 255, 183, 0).withOpacity(0.15),
                                ),
                              ),
                              LineChartBarData(
                                spots: tradeSpots,
                                isCurved: false,
                                color: Colors.transparent,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    final trade = widget.trades![index];
                                    final isLong = trade['type'] == 'LONG';
                                    return FlDotCirclePainter(
                                      radius: 6,
                                      color: isLong ? Colors.green : Colors.red,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ],
                            minX: _minX,
                            maxX: _maxX,
                            minY: minY * 0.999, // 留出一点边距
                            maxY: maxY * 1.001,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // 只在移动端显示返回按钮
            if (isMobile) Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (isMobile) {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown,
                    ]).then((_) {
                      Navigator.of(context).pop();
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 