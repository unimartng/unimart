import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    surface: const Color.fromARGB(255, 244, 244, 244),
    primary: const Color.fromARGB(255, 59, 59, 59),
    secondary: const Color(0xFF0F5A40),
    tertiary: const Color.fromARGB(255, 240, 240, 240),
    inversePrimary: const Color(0xFF0F5A40),
    error: const Color(0xFFE57373),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFFFFFFF),
    elevation: 1,
    iconTheme: IconThemeData(color: const Color(0xFF0F5A40)),
    titleTextStyle: GoogleFonts.poppins(
      color: const Color(0xFF0F5A40),
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
  ),
  textTheme: GoogleFonts.poppinsTextTheme(),
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
    fillColor: const Color(0xFFF2F2F7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: GoogleFonts.poppins(color: const Color(0xFF6E6E6E)),
  ),
);
