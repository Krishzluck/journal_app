import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    _prefs = await SharedPreferences.getInstance();
    final savedThemeMode = _prefs.getString(_themeKey);
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedThemeMode,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString());
    notifyListeners();
  }

  ThemeData get themeData {
    return _themeMode == ThemeMode.dark ? _darkTheme : _lightTheme;
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void resetCurrentIndex() {
    _currentIndex = 0;
    notifyListeners();
  }

  static final ThemeData _lightTheme = ThemeData(
    primaryColor: const Color(0xFF4D6BFE),
    primarySwatch: MaterialColor(0xFF4D6BFE, {
      50: Color(0xFFEEF1FF),
      100: Color(0xFFD4DCFF),
      200: Color(0xFFB7C5FF),
      300: Color(0xFF9AADFF),
      400: Color(0xFF839CFF),
      500: Color(0xFF4D6BFE),
      600: Color(0xFF4763E5),
      700: Color(0xFF3F57CC),
      800: Color(0xFF374BB2),
      900: Color(0xFF2F3F99),
    }),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4D6BFE),
      onPrimary: Colors.white,
    ),
    dividerColor: Colors.grey[200],
  );

  static final ThemeData _darkTheme = ThemeData(
    primaryColor: const Color(0xFF4D6BFE),
    primarySwatch: MaterialColor(0xFF4D6BFE, {
      50: Color(0xFFEEF1FF),
      100: Color(0xFFD4DCFF),
      200: Color(0xFFB7C5FF),
      300: Color(0xFF9AADFF),
      400: Color(0xFF839CFF),
      500: Color(0xFF4D6BFE),
      600: Color(0xFF4763E5),
      700: Color(0xFF3F57CC),
      800: Color(0xFF374BB2),
      900: Color(0xFF2F3F99),
    }),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4D6BFE),
      onPrimary: Colors.white,
    ),
    dividerColor: Colors.grey[800],
  );
} 