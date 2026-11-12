import 'package:material_ui/material_ui.dart';

abstract final class AppColors {
  static const background = Color(0xFF0C0D12);
  static const surface = Color(0xFF15161F);
  static const muted = Color(0xFF9293A8);
  static const purple = Color(0xFFB28AFF);
  static const pink = Color(0xFFFF65BA);
  static const border = Color(0xFF292A39);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: Brightness.dark,
    surface: AppColors.surface,
    primary: AppColors.purple,
    secondary: AppColors.pink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF101119),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    contentPadding: const EdgeInsets.all(18),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -.5,
    ),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
  ),
);
