import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeModeProvider(int savedThemeMode) 
    : _themeMode = ThemeMode.values[savedThemeMode];

  ThemeMode get themeMode => _themeMode;

  void toggleThemeMode() async {
    // Explicitly cycle through light, dark, system modes
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
    
    notifyListeners();
  }
}
