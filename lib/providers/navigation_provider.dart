import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex;
  bool _isInReadingView = false;

  NavigationProvider([int defaultTab = 1]) : _currentIndex = defaultTab;

  int get currentIndex => _currentIndex;
  bool get isInReadingView => _isInReadingView;

  void setTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void enterReadingView() {
    _isInReadingView = true;
    notifyListeners();
  }

  void exitReadingView() {
    _isInReadingView = false;
    notifyListeners();
  }
}
