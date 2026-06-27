import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color lightBg = Color(0xFFECF0F1);
  static const Color darkBg = Color(0xFF2F3542);

  // Accent colors
  static const Color gold = Color(0xFFECC668);      // 硬币、高亮
  static const Color coral = Color(0xFFFF7F50);     // 按钮、强调
  static const Color pink = Color(0xFFFF6B81);      // 防御、软负面
  static const Color steel = Color(0xFF95AFC0);     // 次要、信息
  static const Color red = Color(0xFFD63031);       // LP扣减、删除
  static const Color lightPink = Color(0xFFFF9FF3); // 特殊、魔法
  static const Color orange = Color(0xFFE58E26);    // LP增加、积极

  // Derived
  static const Color lpPositive = Color(0xFF27AE60);
  static const Color lpNegative = Color(0xFFD63031);
}

ThemeData buildLightTheme() {
  const seed = AppColors.steel;
  return ThemeData(
    colorSchemeSeed: seed,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
  );
}

ThemeData buildDarkTheme() {
  const seed = AppColors.steel;
  return ThemeData(
    colorSchemeSeed: seed,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
  );
}
