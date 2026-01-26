import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  // THEME MODE: Currently only Light mode is enabled
  // Dark mode is commented out for now
  // To enable dark mode in future, uncomment the dark mode related code
  
  // Force light mode by default
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  // Always return false since dark mode is disabled
  bool get isDarkMode => false; // _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    // Load theme is disabled - always use light mode
    // _loadTheme();
  }
  
  // Theme loading is disabled - always use light mode
  // Future<void> _loadTheme() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final themeModeIndex = prefs.getInt(_themeKey) ?? 0;
  //   _themeMode = ThemeMode.values[themeModeIndex];
  //   notifyListeners();
  // }
  
  // Theme setting is disabled - always use light mode
  // Future<void> setThemeMode(ThemeMode mode) async {
  //   _themeMode = mode;
  //   notifyListeners();
  //   
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt(_themeKey, mode.index);
  // }
  
  // Theme toggle is disabled - always use light mode
  // Future<void> toggleTheme() async {
  //   if (_themeMode == ThemeMode.dark) {
  //     await setThemeMode(ThemeMode.light);
  //   } else {
  //     await setThemeMode(ThemeMode.dark);
  //   }
  // }
}
