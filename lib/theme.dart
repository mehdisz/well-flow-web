import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFF004080),
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E90FF)),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF004080),
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E90FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    labelStyle: const TextStyle(color: Color(0xFF004080)),
    prefixIconColor: const Color(0xFF004080),
  ),
  fontFamily: 'Vazirmatn', // فونت فارسی یا فونت دلخواه
);
