import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 26, 26, 26),
    primary: const Color.fromARGB(255, 211, 211, 211),
    secondary: const Color(0xFF0F5A40),
    tertiary: const Color.fromARGB(255, 39, 39, 39),
    inversePrimary: const Color(0xFF0F5A40),
    error: const Color(0xFFE57373),
  ),
  scaffoldBackgroundColor: const Color(0xFF23272F),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF242424),
    elevation: 1,
    iconTheme: IconThemeData(color: const Color(0xFFBDBDBD)),
    titleTextStyle: GoogleFonts.poppins(
      color: const Color(0xFFBDBDBD),
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
  ),
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0F5A40),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF23272F),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: GoogleFonts.poppins(color: const Color(0xFFBDBDBD)),
  ),
);
