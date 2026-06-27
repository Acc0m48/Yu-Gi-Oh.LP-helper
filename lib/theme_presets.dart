import 'package:flutter/material.dart';

class ThemePreset {
  final String name;
  final Color lightSeed;
  final Color lightBg;
  final Color darkSeed;
  final Color darkBg;
  final Color lpPositive;
  final Color lpNegative;
  final List<Color> previewColors;

  const ThemePreset({
    required this.name,
    required this.lightSeed,
    required this.lightBg,
    required this.darkSeed,
    required this.darkBg,
    required this.lpPositive,
    required this.lpNegative,
    required this.previewColors,
  });
}

ThemeData buildPresetLight(ThemePreset p) {
  return ThemeData(
    colorSchemeSeed: p.lightSeed,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: p.lightBg,
    cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
  );
}

ThemeData buildPresetDark(ThemePreset p) {
  return ThemeData(
    colorSchemeSeed: p.darkSeed,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: p.darkBg,
    cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
  );
}

const presets = <ThemePreset>[
  ThemePreset(
    name: '棕色',
    lightSeed: Color(0xFFD96C4A),
    lightBg: Color(0xFFF4E0D0),
    darkSeed: Color(0xFFFFB347),
    darkBg: Color(0xFF3B2D26),
    lpPositive: Color(0xFFFF8C42),
    lpNegative: Color(0xFFD96C4A),
    previewColors: [Color(0xFFF4E0D0), Color(0xFFE8D5B7), Color(0xFFF2C2A0), Color(0xFFD96C4A)],
  ),
  ThemePreset(
    name: '黑白',
    lightSeed: Color(0xFF5C6D7E),
    lightBg: Color(0xFFD0DCE4),
    darkSeed: Color(0xFFB0C4DE),
    darkBg: Color(0xFF21303D),
    lpPositive: Color(0xFF5C6D7E),
    lpNegative: Color(0xFF3A4B5C),
    previewColors: [Color(0xFFD0DCE4), Color(0xFF9BA9B5), Color(0xFF5C6D7E), Color(0xFF3A4B5C)],
  ),
  ThemePreset(
    name: '枣色',
    lightSeed: Color(0xFFD36B46),
    lightBg: Color(0xFFFFF2E5),
    darkSeed: Color(0xFFF4A688),
    darkBg: Color(0xFF8B2E2E),
    lpPositive: Color(0xFFD36B46),
    lpNegative: Color(0xFFB94E3A),
    previewColors: [Color(0xFFFFF2E5), Color(0xFFFDE2D7), Color(0xFFFAC8B4), Color(0xFFB94E3A)],
  ),
  ThemePreset(
    name: '蓝紫',
    lightSeed: Color(0xFFB0C4DE),
    lightBg: Color(0xFFD0E2F3),
    darkSeed: Color(0xFFD8B4E2),
    darkBg: Color(0xFF2D1B3D),
    lpPositive: Color(0xFFB0C4DE),
    lpNegative: Color(0xFFC3A4D4),
    previewColors: [Color(0xFFD0E2F3), Color(0xFFB0C4DE), Color(0xFFC3A4D4), Color(0xFFD8B4E2)],
  ),
  ThemePreset(
    name: '自然暖',
    lightSeed: Color(0xFFD9B650),
    lightBg: Color(0xFFFFF8E7),
    darkSeed: Color(0xFFE09F5C),
    darkBg: Color(0xFF6B4E3D),
    lpPositive: Color(0xFF7B8B3A),
    lpNegative: Color(0xFFBC6C5C),
    previewColors: [Color(0xFFFFF8E7), Color(0xFFF5EBD9), Color(0xFFD9B650), Color(0xFFBC6C5C)],
  ),
  ThemePreset(
    name: '自然冷',
    lightSeed: Color(0xFF4A6B5D),
    lightBg: Color(0xFFD0DCE0),
    darkSeed: Color(0xFFA2B9C2),
    darkBg: Color(0xFF2A4E3C),
    lpPositive: Color(0xFF4A6B5D),
    lpNegative: Color(0xFF3A5C62),
    previewColors: [Color(0xFFD0DCE0), Color(0xFFA2B9C2), Color(0xFF4A6B5D), Color(0xFF2A4E3C)],
  ),
  ThemePreset(
    name: '复古',
    lightSeed: Color(0xFFA45A52),
    lightBg: Color(0xFFF5E6D3),
    darkSeed: Color(0xFFE8C87A),
    darkBg: Color(0xFF6B4C3A),
    lpPositive: Color(0xFF3E6B48),
    lpNegative: Color(0xFF923C3C),
    previewColors: [Color(0xFFF5E6D3), Color(0xFFD9B48F), Color(0xFFA45A52), Color(0xFF6B4C3A)],
  ),
  ThemePreset(
    name: '甜品',
    lightSeed: Color(0xFFFFB5A7),
    lightBg: Color(0xFFFFFDF0),
    darkSeed: Color(0xFFFEC89A),
    darkBg: Color(0xFF5C3A3A),
    lpPositive: Color(0xFFFEC89A),
    lpNegative: Color(0xFFFFB5A7),
    previewColors: [Color(0xFFFFFDF0), Color(0xFFFADADD), Color(0xFFFFB5A7), Color(0xFFC4A882)],
  ),
];

class AppColors {
  final ThemePreset preset;
  const AppColors(this.preset);
  Color get lpPositive => preset.lpPositive;
  Color get lpNegative => preset.lpNegative;
  Color get quick500 => colorFrom(0);
  Color get quick1000 => colorFrom(1);
  Color colorFrom(int idx) => preset.previewColors[idx % preset.previewColors.length];
}
