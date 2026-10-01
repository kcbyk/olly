import 'package:flutter/material.dart';

/// Global theme mode notifier.
/// Defaults to light mode as per current design, but can be switched to dark or system.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

bool get isDarkMode => appThemeMode.value == ThemeMode.dark;

void toggleTheme(bool isDark) {
  appThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
}
