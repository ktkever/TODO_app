import 'package:flutter/material.dart';

// 여러 화면에서 공통으로 쓰는 라이트/다크 색상 묶음.
class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color selectedBg;
  final Color itemSelectedBg;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.selectedBg,
    required this.itemSelectedBg,
  });

  static const accent = Color(0xFF0078D4);

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = AppColors(
    background: Colors.white,
    surface: Color(0xFFF3F2F1),
    surfaceAlt: Color(0xFFF9F9F9),
    border: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF333333),
    textMuted: Color(0xFF767676),
    selectedBg: Color(0xFFDEECF9),
    itemSelectedBg: Color(0xFFEFF6FC),
  );

  static const dark = AppColors(
    background: Color(0xFF1F1F1F),
    surface: Color(0xFF272727),
    surfaceAlt: Color(0xFF2D2D2D),
    border: Color(0xFF3D3D3D),
    textPrimary: Color(0xFFF3F3F3),
    textSecondary: Color(0xFFD0D0D0),
    textMuted: Color(0xFFA0A0A0),
    selectedBg: Color(0xFF264A66),
    itemSelectedBg: Color(0xFF23384A),
  );
}
