import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color palette ───────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const blue900 = Color(0xFF06175C);
  static const blue800 = Color(0xFF0B2FBF);
  static const blue700 = Color(0xFF1E46E0);
  static const blue500 = Color(0xFF3E6BFF);
  static const blue200 = Color(0xFFB9C8FF);
  static const blue50  = Color(0xFFE9EDFF);

  static const ball     = Color(0xFFDFFF3A); // tennis-ball lime
  static const ballSoft = Color(0xFFEEFFA8);
  static const ballDeep = Color(0xFFBFE000);

  static const ink   = Color(0xFF0A1238);
  static const paper = Color(0xFFF6F4EE);
  static const mist  = Color(0xFFE8E3D6);
  static const line  = Color(0x1F0A1238); // rgba(10,18,56,0.12)

  static const success = Color(0xFF13B07B);
  static const warn    = Color(0xFFFFB020);
  static const hot     = Color(0xFFFF5A3C);
}

// ─── Typography ──────────────────────────────────────────────────────────────
class AppFonts {
  AppFonts._();

  static TextStyle display(
    double size, {
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
    FontWeight weight = FontWeight.w900,
  }) =>
      GoogleFonts.archivoBlack(
        fontSize: size,
        color: color,
        letterSpacing: letterSpacing ?? size * -0.02,
        height: height,
        fontWeight: weight,
      );

  static TextStyle body(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing ?? size * 0.02,
      );
}

// ─── 5-tier level system ─────────────────────────────────────────────────────
class AppLevel {
  const AppLevel({
    required this.tier,
    required this.key,
    required this.label,
    required this.rangeMin,
    required this.rangeMax,
    required this.color,
    required this.fg,
    required this.desc,
  });

  final int tier;
  final String key;
  final String label;
  final double rangeMin;
  final double rangeMax;
  final Color color;
  final Color fg;
  final String desc;
}

const kLevels = <AppLevel>[
  AppLevel(
    tier: 1, key: 'rookie', label: 'Rookie',
    rangeMin: 0, rangeMax: 1.5,
    color: Color(0xFFB9E6FF), fg: AppColors.blue900,
    desc: 'Brand new. Learning paddle grip + serve basics.',
  ),
  AppLevel(
    tier: 2, key: 'amateur', label: 'Amateur',
    rangeMin: 1.5, rangeMax: 2.5,
    color: Color(0xFFC6FF9C), fg: AppColors.ink,
    desc: 'Rallies for a few shots. Working on consistency.',
  ),
  AppLevel(
    tier: 3, key: 'regular', label: 'Regular',
    rangeMin: 2.5, rangeMax: 3.5,
    color: AppColors.ball, fg: AppColors.ink,
    desc: 'Solid play, reads the court, chooses shots.',
  ),
  AppLevel(
    tier: 4, key: 'pro', label: 'Pro',
    rangeMin: 3.5, rangeMax: 4.5,
    color: AppColors.warn, fg: AppColors.ink,
    desc: 'Strategic, sharp footwork, controls the net.',
  ),
  AppLevel(
    tier: 5, key: 'elite', label: 'Elite',
    rangeMin: 4.5, rangeMax: 10,
    color: AppColors.hot, fg: Colors.white,
    desc: 'Tournament-grade. Smashes, viboras, bandejas.',
  ),
];

AppLevel levelForRating(double r) =>
    kLevels.firstWhere(
      (l) => r >= l.rangeMin && r < l.rangeMax,
      orElse: () => kLevels[2],
    );

AppLevel levelByKey(String k) =>
    kLevels.firstWhere((l) => l.key == k, orElse: () => kLevels[2]);

// ─── Design constants ─────────────────────────────────────────────────────────
const kBorderRadius = 16.0;
const kBorderRadiusLg = 22.0;
const kBorderRadiusPill = 999.0;
const kScreenPadding = 20.0;
const kNavHeight = 80.0; // height of floating nav bar + safe area
