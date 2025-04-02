import 'package:flutter/foundation.dart';

class SidebarProvider with ChangeNotifier {
  bool _isExpanded = true;

  bool get isExpanded => _isExpanded;

  void toggleSidebar() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }
} 