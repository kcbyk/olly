import 'package:flutter/material.dart';

/// Olly's dynamic editorial colour system supporting both Light and Dark themes.
abstract final class AppColors {
  // ─── Light Surfaces & Backgrounds ────────────────────────────
  static const background = Color(0xFFF7F7F3);
  static const backgroundSecondary = Color(0xFFEDEEE8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF1F2ED);
  static const surfaceVariant = Color(0xFFE7E9E2);
  static const surfaceHighlight = Color(0xFFDDE1D7);

  // ─── Modern Premium Dark Surfaces & Backgrounds ──────────────
  static const darkBackground = Color(0xFF000000);
  static const darkBackgroundSecondary = Color(0xFF0D0D0D);
  static const darkSurface = Color(0xFF262626);
  static const darkSurfaceElevated = Color(0xFF262626);
  static const darkSurfaceVariant = Color(0xFF333333);
  static const darkSurfaceHighlight = Color(0xFF3D3D3D);

  // Fallbacks
  static const backgroundLight = Color(0xFFF7F7F3);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFEEF2F6);
  static const backgroundDark = Color(0xFF000000);
  static const surfaceDark = Color(0xFF262626);
  static const surfaceVariantDark = Color(0xFF333333);

  // ─── Marka Renkleri ──────────────────────────────────────────
  static const primary = Color(0xFF173F35);
  static const primaryLight = Color(0xFF2D6A58);
  static const primaryDark = Color(0xFF0E2821);

  static const darkPrimary = Color(0xFF10B981);
  static const darkPrimaryLight = Color(0xFF34D399);
  static const darkPrimaryDark = Color(0xFF059669);

  static const secondary = Color(0xFFC45834);
  static const tertiary = Color(0xFFC45834);
  static const accent = Color(0xFF2D6A58);

  static const darkSecondary = Color(0xFFF43F5E);
  static const darkTertiary = Color(0xFFF43F5E);
  static const darkAccent = Color(0xFF6366F1);

  // ─── Sosyal ve Canlı Durum Renkleri ──────────────────────────
  static const live = Color(0xFFC45834);
  static const online = Color(0xFF2E7D5B);
  static const idle = Color(0xFFB17A28);
  static const offline = Color(0xFF8B918B);
  static const speaking = online;
  static const muted = Color(0xFFB94E4E);

  static const darkLive = Color(0xFFF43F5E);
  static const darkOnline = Color(0xFF10B981);
  static const darkIdle = Color(0xFFF59E0B);
  static const darkOffline = Color(0xFFA8A8A8);
  static const darkSpeaking = darkOnline;
  static const darkMuted = Color(0xFFEF4444);

  // ─── Metin Renkleri ──────────────────────────────────────────
  static const textPrimary = Color(0xFF19221E);
  static const textSecondary = Color(0xFF59635D);
  static const textTertiary = Color(0xFF7D8780);
  static const textMuted = Color(0xFFB94E4E);
  static const textInverse = Color(0xFFF9FAF7);

  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA8A8A8);
  static const darkTextTertiary = Color(0xFFA8A8A8);
  static const darkTextMuted = Color(0xFFEF4444);
  static const darkTextInverse = Color(0xFF000000);

  // ─── Glassmorphism & Borders ─────────────────────────────────
  static const glassSurface = Color(0xEBFFFFFF);
  static const glassBorder = Color(0x1A17231D);
  static const glassBorderHighlight = Color(0x3317231D);
  static const glassBorderSubtle = Color(0x0D17231D);

  static const darkGlassSurface = Color(0xEB262626);
  static const darkGlassBorder = Color(0x29FFFFFF);
  static const darkGlassBorderHighlight = Color(0x40FFFFFF);
  static const darkGlassBorderSubtle = Color(0x1FFFFFFF);

  // ─── Floating Pill Bar ───────────────────────────────────────
  static const pillBarBackground = Color(0xF7FFFFFF);
  static const pillActiveBackground = Color(0x1A173F35);

  static const darkPillBarBackground = Color(0xF0262626);
  static const darkPillActiveBackground = Colors.transparent;

  // ─── Gradients ───────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF173F35), Color(0xFF285D4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const voiceRoomGradient = LinearGradient(
    colors: [Color(0xFF173F35), Color(0xFF2D6A58)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkVoiceRoomGradient = LinearGradient(
    colors: [Color(0xFF262626), Color(0xFF1F1F1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF6F7F2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const darkCardGradient = LinearGradient(
    colors: [Color(0xFF262626), Color(0xFF222222)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const glowingBorderGradient = LinearGradient(
    colors: [Color(0x66173F35), Color(0x1AC45834), Color(0x662D6A58)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const liveBadgeGradient = LinearGradient(
    colors: [Color(0xFFC45834), Color(0xFFA54428)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const darkLiveBadgeGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Helper to get theme-aware colors based on context
  static OllyPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkPalette : _lightPalette;
  }

  static const _lightPalette = OllyPalette(
    isDark: false,
    background: background,
    backgroundSecondary: backgroundSecondary,
    surface: surface,
    surfaceElevated: surfaceElevated,
    surfaceVariant: surfaceVariant,
    surfaceHighlight: surfaceHighlight,
    primary: primary,
    primaryLight: primaryLight,
    primaryDark: primaryDark,
    secondary: secondary,
    accent: accent,
    live: live,
    online: online,
    idle: idle,
    offline: offline,
    speaking: speaking,
    muted: muted,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    textMuted: textMuted,
    textInverse: textInverse,
    glassBorder: glassBorder,
    glassBorderHighlight: glassBorderHighlight,
    glassBorderSubtle: glassBorderSubtle,
    pillBarBackground: pillBarBackground,
    pillActiveBackground: pillActiveBackground,
    primaryGradient: primaryGradient,
    voiceRoomGradient: voiceRoomGradient,
    cardGradient: cardGradient,
    liveBadgeGradient: liveBadgeGradient,
  );

  static const _darkPalette = OllyPalette(
    isDark: true,
    background: darkBackground,
    backgroundSecondary: darkBackgroundSecondary,
    surface: darkSurface,
    surfaceElevated: darkSurfaceElevated,
    surfaceVariant: darkSurfaceVariant,
    surfaceHighlight: darkSurfaceHighlight,
    primary: darkPrimary,
    primaryLight: darkPrimaryLight,
    primaryDark: darkPrimaryDark,
    secondary: darkSecondary,
    accent: darkAccent,
    live: darkLive,
    online: darkOnline,
    idle: darkIdle,
    offline: darkOffline,
    speaking: darkSpeaking,
    muted: darkMuted,
    textPrimary: darkTextPrimary,
    textSecondary: darkTextSecondary,
    textTertiary: darkTextTertiary,
    textMuted: darkTextMuted,
    textInverse: darkTextInverse,
    glassBorder: darkGlassBorder,
    glassBorderHighlight: darkGlassBorderHighlight,
    glassBorderSubtle: darkGlassBorderSubtle,
    pillBarBackground: darkPillBarBackground,
    pillActiveBackground: darkPillActiveBackground,
    primaryGradient: darkPrimaryGradient,
    voiceRoomGradient: darkVoiceRoomGradient,
    cardGradient: darkCardGradient,
    liveBadgeGradient: darkLiveBadgeGradient,
  );
}

/// Palette class for dynamic theme access
class OllyPalette {
  const OllyPalette({
    required this.isDark,
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceVariant,
    required this.surfaceHighlight,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.live,
    required this.online,
    required this.idle,
    required this.offline,
    required this.speaking,
    required this.muted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.textInverse,
    required this.glassBorder,
    required this.glassBorderHighlight,
    required this.glassBorderSubtle,
    required this.pillBarBackground,
    required this.pillActiveBackground,
    required this.primaryGradient,
    required this.voiceRoomGradient,
    required this.cardGradient,
    required this.liveBadgeGradient,
  });

  final bool isDark;
  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceVariant;
  final Color surfaceHighlight;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color live;
  final Color online;
  final Color idle;
  final Color offline;
  final Color speaking;
  final Color muted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textMuted;
  final Color textInverse;
  final Color glassBorder;
  final Color glassBorderHighlight;
  final Color glassBorderSubtle;
  final Color pillBarBackground;
  final Color pillActiveBackground;
  final LinearGradient primaryGradient;
  final LinearGradient voiceRoomGradient;
  final LinearGradient cardGradient;
  final LinearGradient liveBadgeGradient;
}
