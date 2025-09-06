import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  late SharedPreferences _prefs;
  final FlutterTts _flutterTts = FlutterTts();

  // Accessibility settings
  bool _highContrastMode = false;
  bool _largeTextMode = false;
  bool _screenReaderEnabled = false;
  bool _voiceOverEnabled = false;
  double _textScaleFactor = 1.0;
  double _speechRate = 0.5;
  String _selectedLanguage = 'en';

  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAccessibilitySettings();
    await _initializeTTS();
  }

  // Initialize TTS
  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage(_selectedLanguage);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('Failed to initialize TTS: $e');
    }
  }

  // Load accessibility settings
  Future<void> _loadAccessibilitySettings() async {
    try {
      _highContrastMode = _prefs.getBool('high_contrast_mode') ?? false;
      _largeTextMode = _prefs.getBool('large_text_mode') ?? false;
      _screenReaderEnabled = _prefs.getBool('screen_reader_enabled') ?? false;
      _voiceOverEnabled = _prefs.getBool('voice_over_enabled') ?? false;
      _textScaleFactor = _prefs.getDouble('text_scale_factor') ?? 1.0;
      _speechRate = _prefs.getDouble('speech_rate') ?? 0.5;
      _selectedLanguage = _prefs.getString('selected_language') ?? 'en';
    } catch (e) {
      debugPrint('Failed to load accessibility settings: $e');
    }
  }

  // Save accessibility settings
  Future<void> _saveAccessibilitySettings() async {
    try {
      await _prefs.setBool('high_contrast_mode', _highContrastMode);
      await _prefs.setBool('large_text_mode', _largeTextMode);
      await _prefs.setBool('screen_reader_enabled', _screenReaderEnabled);
      await _prefs.setBool('voice_over_enabled', _voiceOverEnabled);
      await _prefs.setDouble('text_scale_factor', _textScaleFactor);
      await _prefs.setDouble('speech_rate', _speechRate);
      await _prefs.setString('selected_language', _selectedLanguage);
    } catch (e) {
      debugPrint('Failed to save accessibility settings: $e');
    }
  }

  // High contrast mode
  bool get highContrastMode => _highContrastMode;

  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    await _saveAccessibilitySettings();
  }

  // Large text mode
  bool get largeTextMode => _largeTextMode;

  Future<void> setLargeTextMode(bool enabled) async {
    _largeTextMode = enabled;
    await _saveAccessibilitySettings();
  }

  // Screen reader
  bool get screenReaderEnabled => _screenReaderEnabled;

  Future<void> setScreenReaderEnabled(bool enabled) async {
    _screenReaderEnabled = enabled;
    await _saveAccessibilitySettings();
  }

  // Voice over
  bool get voiceOverEnabled => _voiceOverEnabled;

  Future<void> setVoiceOverEnabled(bool enabled) async {
    _voiceOverEnabled = enabled;
    await _saveAccessibilitySettings();
  }

  // Text scale factor
  double get textScaleFactor => _textScaleFactor;

  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    await _saveAccessibilitySettings();
  }

  // Speech rate
  double get speechRate => _speechRate;

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _saveAccessibilitySettings();
  }

  // Selected language
  String get selectedLanguage => _selectedLanguage;

  Future<void> setSelectedLanguage(String language) async {
    _selectedLanguage = language;
    await _saveAccessibilitySettings();
    await _initializeTTS();
  }

  // Speak text
  Future<void> speak(String text) async {
    if (_voiceOverEnabled) {
      try {
        await _flutterTts.speak(text);
      } catch (e) {
        debugPrint('Failed to speak text: $e');
      }
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Failed to stop speaking: $e');
    }
  }

  // Get accessibility theme
  ThemeData getAccessibilityTheme() {
    if (_highContrastMode) {
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.black,
          onPrimary: Colors.yellow,
          surface: Colors.black,
          onSurface: Colors.yellow,
        ),
        textTheme: _largeTextMode
            ? ThemeData.light().textTheme.apply(fontSizeFactor: 1.5)
            : ThemeData.light().textTheme,
      );
    } else if (_largeTextMode) {
      return ThemeData(
        textTheme: ThemeData.light().textTheme.apply(fontSizeFactor: 1.5),
      );
    }

    return ThemeData.light();
  }

  // Get accessibility summary
  Map<String, dynamic> getAccessibilitySummary() {
    return {
      'highContrastMode': _highContrastMode,
      'largeTextMode': _largeTextMode,
      'screenReaderEnabled': _screenReaderEnabled,
      'voiceOverEnabled': _voiceOverEnabled,
      'textScaleFactor': _textScaleFactor,
      'speechRate': _speechRate,
      'selectedLanguage': _selectedLanguage,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Get accessibility status (alias for getAccessibilitySummary)
  Map<String, dynamic> getAccessibilityStatus() {
    return getAccessibilitySummary();
  }
}
