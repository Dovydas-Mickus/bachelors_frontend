import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme(brightness: Brightness.light, primary: Colors.green.shade500, onPrimary: Colors.white, secondary: Colors.grey.shade200, onSecondary: Colors.black, error: Colors.red, onError: Colors.black, surface: Colors.white, onSurface: Colors.black),
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.grey.shade200),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.green.shade500,
  ),
);



ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme(brightness: Brightness.dark, primary: Colors.green.shade500, onPrimary: Colors.grey.shade200, secondary: Color(0xFF1E1E20), onSecondary: Colors.grey.shade200, error: Colors.red, onError: Colors.white, surface: Color(0xFF161618), onSurface: Color(0XFFFFFFFF)),
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.grey.shade800),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.green.shade500,
    foregroundColor: Colors.grey.shade300
  ),
);
