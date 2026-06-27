import 'package:flutter/material.dart';

class AppColors {
  // Brown palette — light to deep
  static const Color cream = Color(0xFFF4E0D0);       // 最浅 - 背景
  static const Color beige = Color(0xFFE8D5B7);       // 浅米 - 卡片/表面
  static const Color peach = Color(0xFFF2C2A0);       // 桃色 - 容器
  static const Color gold = Color(0xFFFFB347);         // 金黄 - 强调/硬币
  static const Color amber = Color(0xFFFF8C42);        // 琥珀 - 积极/按钮
  static const Color brown = Color(0xFFC4A484);        // 棕色 - 次级文本
  static const Color terracotta = Color(0xFFD96C4A);   // 赤陶 - 主色/负面
  static const Color coral = Color(0xFFF08080);        // 珊瑚 - 警告/软负面

  // Semantic
  static const Color lpPositive = Color(0xFFFF8C42);
  static const Color lpNegative = Color(0xFFD96C4A);
  static const Color coinColor = Color(0xFFFFB347);
  static const Color diceColor = Color(0xFFD96C4A);
  static const Color quick500 = Color(0xFFC4A484);
  static const Color quick1000 = Color(0xFFD96C4A);
}

ThemeData buildLightTheme() {
  const seed = AppColors.terracotta;
  return ThemeData(
    colorSchemeSeed: seed,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.cream,
    cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.beige,
      foregroundColor: Color(0xFF5D3A2E),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.beige,
      indicatorColor: AppColors.peach,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
    ),
  );
}

ThemeData buildDarkTheme() {
  const seed = AppColors.gold;
  return ThemeData(
    colorSchemeSeed: seed,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF3B2D26),
    cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4A382F),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF4A382F),
      indicatorColor: AppColors.brown.withOpacity(0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A1F1A),
    ),
  );
}
