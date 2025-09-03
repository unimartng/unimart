import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimart/constants/light_mode.dart';
import 'package:unimart/constants/dark_mode.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;
  bool _useSystemTheme = true;

  ThemeProvider() : _themeData = _getInitialTheme() {
    _loadTheme();
    _listenToSystemTheme();
  }

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _themeData == darkMode;
  bool get useSystemTheme => _useSystemTheme;

  /// Get initial theme synchronously to prevent white flash
  static ThemeData _getInitialTheme() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return (brightness == Brightness.dark) ? darkMode : lightMode;
  }

  /// Listen to system theme changes
  void _listenToSystemTheme() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
          if (_useSystemTheme) {
            final newTheme = _getInitialTheme();
            if (_themeData != newTheme) {
              _themeData = newTheme;
              notifyListeners();
            }
          }
        };
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user wants to use system theme
      _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;

      if (_useSystemTheme) {
        // Use system theme
        final newTheme = _getInitialTheme();
        if (_themeData != newTheme) {
          _themeData = newTheme;
          notifyListeners();
        }
      } else if (prefs.containsKey('isDarkMode')) {
        // Use saved theme preference
        final isDark = prefs.getBool('isDarkMode')!;
        final newTheme = isDark ? darkMode : lightMode;
        if (_themeData != newTheme) {
          _themeData = newTheme;
          notifyListeners();
        }
      }
    } catch (e) {
      // If there's an error loading preferences, keep the initial theme
      print('Error loading theme preferences: $e');
    }
  }

  Future<void> setThemeMode(ThemeData themeData) async {
    _themeData = themeData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', themeData == darkMode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeData == lightMode) {
      _themeData = darkMode;
    } else {
      _themeData = lightMode;
    }
    _useSystemTheme = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeData == darkMode);
    await prefs.setBool('useSystemTheme', false);
    notifyListeners();
  }

  Future<void> setSystemTheme() async {
    _useSystemTheme = true;
    final newTheme = _getInitialTheme();
    if (_themeData != newTheme) {
      _themeData = newTheme;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', true);
    await prefs.remove('isDarkMode');
    notifyListeners();
  }
}
