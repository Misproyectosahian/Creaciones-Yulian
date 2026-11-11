import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const pink50 = Color(0xFFFFF5F9);
  static const pink100 = Color(0xFFFFE4EF);
  static const pink200 = Color(0xFFFFC8DE);
  static const pink300 = Color(0xFFFF9FC4);
  static const pink400 = Color(0xFFF77FAE);
  static const pink500 = Color(0xFFE85D97);
  static const pink600 = Color(0xFFD63F7C);
  static const lilac50 = Color(0xFFF8F3FF);
  static const lilac100 = Color(0xFFF1E8FF);
  static const lilac200 = Color(0xFFE2D1FF);
  static const lilac300 = Color(0xFFC9AEFC);
  static const lilac500 = Color(0xFF9B7BE0);
  static const lilac700 = Color(0xFF6B4FB5);
  static const ink = Color(0xFF4A3856);
  static const muted = Color(0xFF8A7896);
  static const mint = Color(0xFF7FD8B5);
  static const butter = Color(0xFFFFE08A);
  static const bg = Color(0xFFFFFAFC);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink100, lilac100],
  );

  static const strongGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink400, lilac500],
  );
}

TextStyle fredoka({double? size, FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color ?? AppColors.ink);

TextStyle pacifico({double? size, Color? color}) =>
    GoogleFonts.pacifico(fontSize: size, color: color ?? AppColors.pink600);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.pink500,
    primary: AppColors.pink600,
    secondary: AppColors.lilac500,
    surface: Colors.white,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );
  TextStyle? fred(TextStyle? s, [FontWeight w = FontWeight.w600]) =>
      s == null ? null : GoogleFonts.fredoka(textStyle: s, fontWeight: w);

  final radius16 = BorderRadius.circular(16);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: text.copyWith(
      headlineLarge: fred(text.headlineLarge),
      headlineMedium: fred(text.headlineMedium),
      headlineSmall: fred(text.headlineSmall),
      titleLarge: fred(text.titleLarge),
      titleMedium: fred(text.titleMedium, FontWeight.w500),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      centerTitle: false,
      titleTextStyle: fredoka(size: 24),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.pink100, width: 1.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: radius16, borderSide: const BorderSide(color: AppColors.pink200)),
      enabledBorder: OutlineInputBorder(borderRadius: radius16, borderSide: const BorderSide(color: AppColors.pink200)),
      focusedBorder: OutlineInputBorder(borderRadius: radius16, borderSide: const BorderSide(color: AppColors.pink400, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: radius16, borderSide: const BorderSide(color: Color(0xFFE05A6F))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: radius16, borderSide: const BorderSide(color: Color(0xFFE05A6F), width: 2)),
      labelStyle: const TextStyle(color: AppColors.muted),
      floatingLabelStyle: const TextStyle(color: AppColors.pink600, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.7)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.pink600,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.fredoka(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.pink600,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: AppColors.pink300, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.pink600,
        textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.pink600,
      foregroundColor: Colors.white,
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.pink100,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? AppColors.pink600 : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.pink600 : AppColors.muted,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.pink100,
      checkmarkColor: AppColors.pink600,
      side: const BorderSide(color: AppColors.pink200),
      shape: const StadiumBorder(),
      labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      actionTextColor: AppColors.pink200,
      contentTextStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      titleTextStyle: fredoka(size: 21),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : AppColors.pink200,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.pink500 : AppColors.pink50,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.pink200),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.pink100, thickness: 1.2),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.pink500),
  );
}
