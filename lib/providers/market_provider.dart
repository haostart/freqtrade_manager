import 'package:flutter/foundation.dart';

class MarketProvider with ChangeNotifier {
  Map<String, dynamic> _marketData = {};
  final List<Map<String, dynamic>> _trades = [];

  Map<String, dynamic> get marketData => _marketData;
  List<Map<String, dynamic>> get trades => _trades;

  void updateMarketData(Map<String, dynamic> data) {
    _marketData = data;
    notifyListeners();
  }

  void addTrade(Map<String, dynamic> trade) {
    _trades.insert(0, trade);
    if (_trades.length > 100) {
      _trades.removeLast();
    }
    notifyListeners();
  }
} 