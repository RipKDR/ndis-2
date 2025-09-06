import 'package:flutter/material.dart';

class AppSettingsViewModel extends ChangeNotifier {
  bool _highContrast = false;
  double _textScale = 1.0; // 1.0 = 100%
  Locale? _locale;

  bool get highContrast => _highContrast;
  double get textScale => _textScale;
  Locale? get locale => _locale;

  void toggleHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  void setTextScale(double factor) {
    _textScale = factor.clamp(0.8, 2.0);
    notifyListeners();
  }

  void setLocale(Locale? locale) {
    _locale = locale;
    notifyListeners();
  }
}

