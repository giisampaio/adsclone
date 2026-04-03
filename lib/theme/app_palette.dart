import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic colors for SaaS UI (light / dark).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.accent,
    required this.secondary,
    required this.tertiary,
    required this.text,
    required this.muted,
    required this.dim,
    required this.border,
    required this.sidebar,
    required this.sidebarBorder,
    required this.navSelected,
    required this.onAccent,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color accent;
  final Color secondary;
  final Color tertiary;
  final Color text;
  final Color muted;
  final Color dim;
  final Color border;
  final Color sidebar;
  final Color sidebarBorder;
  final Color navSelected;
  final Color onAccent;

  LinearGradient get heroGradient => LinearGradient(
        colors: [accent, secondary, tertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  TextStyle mono({
    double fontSize = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: fontSize,
      fontWeight: weight,
      color: color ?? text,
    );
  }

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0A0A0F),
    surface: Color(0xFF12121A),
    surfaceElevated: Color(0xFF18182A),
    accent: Color(0xFF6C5CE7),
    secondary: Color(0xFF00CEFF),
    tertiary: Color(0xFFFF6B9D),
    text: Color(0xFFF0F0F5),
    muted: Color(0xFF8888A0),
    dim: Color(0xFF55556A),
    border: Color(0xFF2A2A38),
    sidebar: Color(0xFF0D0D14),
    sidebarBorder: Color(0xFF22222E),
    navSelected: Color(0x266C5CE7),
    onAccent: Color(0xFFFFFFFF),
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF1F5F9),
    accent: Color(0xFF5B4FD6),
    secondary: Color(0xFF0284C7),
    tertiary: Color(0xFFDB2777),
    text: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    dim: Color(0xFF94A3B8),
    border: Color(0xFFE2E8F0),
    sidebar: Color(0xFFFFFFFF),
    sidebarBorder: Color(0xFFE2E8F0),
    navSelected: Color(0x1A5B4FD6),
    onAccent: Color(0xFFFFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? accent,
    Color? secondary,
    Color? tertiary,
    Color? text,
    Color? muted,
    Color? dim,
    Color? border,
    Color? sidebar,
    Color? sidebarBorder,
    Color? navSelected,
    Color? onAccent,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      accent: accent ?? this.accent,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      dim: dim ?? this.dim,
      border: border ?? this.border,
      sidebar: sidebar ?? this.sidebar,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      navSelected: navSelected ?? this.navSelected,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      dim: Color.lerp(dim, other.dim, t)!,
      border: Color.lerp(border, other.border, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      navSelected: Color.lerp(navSelected, other.navSelected, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get p => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
