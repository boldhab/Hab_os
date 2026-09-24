import 'package:flutter/material.dart';

class AppTheme {
  static const _fontFamilyFallback = ['Segoe UI', 'Roboto', 'Arial', 'sans-serif'];

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
        fontFamilyFallback: _fontFamilyFallback,
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        fontFamilyFallback: _fontFamilyFallback,
      );
}
