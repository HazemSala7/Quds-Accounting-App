import 'package:flutter/material.dart';

class RefreshProvider extends ChangeNotifier {
  bool _shouldRefresh = false;

  bool get shouldRefresh => _shouldRefresh;

  void setShouldRefresh(bool value) {
    _shouldRefresh = value;
    notifyListeners();
  }
}
