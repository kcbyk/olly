import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF173F35),
          secondary: Color(0xFFC45834),
          surface: Color(0xFFFFFFFF),
          error: Color(0xFFB94E4E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF19221E),
        ),
        fontFamily: 'Segoe UI',
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF19221E),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
          iconTheme: IconThemeData(color: Color(0xFF19221E)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F2ED),
          hintStyle:
              const TextStyle(color: Color(0xFF7D8780), fontSize: 14),
          prefixIconColor: const Color(0xFF59635D),
          suffixIconColor: const Color(0xFF59635D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1A17231D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1A17231D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF173F35), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x1A17231D)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x0D17231D),
          thickness: 1,
          space: 1,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFFF43F5E),
          surface: Color(0xFF262626),
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFFFFFFF),
        ),
        fontFamily: 'Segoe UI',
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
          iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF262626),
          hintStyle:
              const TextStyle(color: Color(0xFFA8A8A8), fontSize: 14),
          prefixIconColor: const Color(0xFFA8A8A8),
          suffixIconColor: const Color(0xFFA8A8A8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x29FFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x29FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF262626),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x29FFFFFF)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x1FFFFFFF),
          thickness: 1,
          space: 1,
        ),
      );
}
