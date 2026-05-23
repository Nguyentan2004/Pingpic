import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale_lang';

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode for rich visual style
  Locale _locale = const Locale('vi');  // Default to Vietnamese

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  Locale get locale => _locale;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      }
      
      // Load locale
      final langCode = prefs.getString(_localeKey);
      if (langCode != null) {
        _locale = Locale(langCode);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> changeLocale(String langCode) async {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, langCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }
}
