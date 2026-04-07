import 'package:flutter/foundation.dart';

class SidebarProvider extends ChangeNotifier {
  bool _isOpen = true;
  
  bool get isOpen => _isOpen;
  
  void toggle() {
    _isOpen = !_isOpen;
    notifyListeners();
  }
  
  void open() {
    _isOpen = true;
    notifyListeners();
  }
  
  void close() {
    _isOpen = false;
    notifyListeners();
  }
}

