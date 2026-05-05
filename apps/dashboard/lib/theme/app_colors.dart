import 'package:flutter/material.dart';

/// Semantic color tokens for the OpenCI dashboard.
///
/// Usage: `context.appColors.surface` or `AppColors.of(context).surface`
///
/// These tokens follow the IMA-flavored Material palette:
/// - Light mode: soft slate backgrounds, white cards, blue seed accent
/// - Dark mode: Material dark slate surfaces with the same blue accent
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    // ── Backgrounds ──
    required this.scaffold,
    required this.surface,
    required this.surfaceHover,
    required this.surfaceSecondary,
    required this.surfaceTertiary,

    // ── Borders ──
    required this.border,
    required this.borderSubtle,
    required this.borderFocused,

    // ── Text ──
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,

    // ── Accent (Brand Blue) ──
    required this.accent,
    required this.accentHover,
    required this.accentSubtle,
    required this.accentOnAccent,

    // ── Status ──
    required this.success,
    required this.successSubtle,
    required this.error,
    required this.errorSubtle,
    required this.warning,
    required this.warningSubtle,

    // ── Semantic ──
    required this.codeBackground,
    required this.overlay,
    required this.divider,
    required this.shimmer,
  });

  // ── Backgrounds ──
  /// Main scaffold background.
  final Color scaffold;

  /// Primary card / container surface.
  final Color surface;

  /// Surface on hover.
  final Color surfaceHover;

  /// Secondary container (nested card, sidebar).
  final Color surfaceSecondary;

  /// Tertiary surface (code blocks, logs).
  final Color surfaceTertiary;

  // ── Borders ──
  /// Default border color.
  final Color border;

  /// Subtle border (cards, dividers).
  final Color borderSubtle;

  /// Focused / selected border.
  final Color borderFocused;

  // ── Text ──
  /// Primary text (headings, body).
  final Color textPrimary;

  /// Secondary text (labels, hints).
  final Color textSecondary;

  /// Tertiary text (timestamps, muted).
  final Color textTertiary;

  /// Inverse text (on dark surfaces when in light mode, etc).
  final Color textInverse;

  // ── Accent ──
  /// Primary accent color (buttons, links).
  final Color accent;

  /// Accent hover state.
  final Color accentHover;

  /// Subtle accent (backgrounds, badges).
  final Color accentSubtle;

  /// Text on accent backgrounds.
  final Color accentOnAccent;

  // ── Status ──
  final Color success;
  final Color successSubtle;
  final Color error;
  final Color errorSubtle;
  final Color warning;
  final Color warningSubtle;

  // ── Semantic ──
  /// Code / log viewer background.
  final Color codeBackground;

  /// Overlay for modals, bottom sheets.
  final Color overlay;

  /// Divider line.
  final Color divider;

  /// Skeleton / shimmer loading.
  final Color shimmer;

  /// Convenience accessor from BuildContext.
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Dark Theme
  // ═══════════════════════════════════════════════════════════════════
  static const dark = AppColors(
    // Backgrounds
    scaffold: Color(0xFF0F172A), // slate-900
    surface: Color(0xFF111827), // gray-900
    surfaceHover: Color(0xFF1E293B), // slate-800
    surfaceSecondary: Color(0xFF1E293B), // slate-800
    surfaceTertiary: Color(0xFF334155), // slate-700
    // Borders
    border: Color(0x1FFFFFFF), // white 12%
    borderSubtle: Color(0x12FFFFFF), // white 7%
    borderFocused: Color(0xFF2563EB), // blue-600
    // Text
    textPrimary: Color(0xFFFFFFFF), // white
    textSecondary: Color(0xB3FFFFFF), // white 70%
    textTertiary: Color(0x66FFFFFF), // white 40%
    textInverse: Color(0xFF0A0A0A), // zinc-950
    // Accent
    accent: Color(0xFF2563EB), // blue-600
    accentHover: Color(0xFF1D4ED8), // blue-700
    accentSubtle: Color(0x262563EB), // blue-600 15%
    accentOnAccent: Color(0xFFFFFFFF), // white
    // Status
    success: Color(0xFF22C55E), // green-500
    successSubtle: Color(0x2622C55E), // green-500 15%
    error: Color(0xFFEF4444), // red-500
    errorSubtle: Color(0x26EF4444), // red-500 15%
    warning: Color(0xFFD29922), // amber-600
    warningSubtle: Color(0x26D29922), // amber-600 15%
    // Semantic
    codeBackground: Color(0xFF1E293B), // slate-800
    overlay: Color(0x80000000), // black 50%
    divider: Color(0x14FFFFFF), // white 8%
    shimmer: Color(0x0AFFFFFF), // white 4%
  );

  // ═══════════════════════════════════════════════════════════════════
  // Light Theme
  // ═══════════════════════════════════════════════════════════════════
  static const light = AppColors(
    // Backgrounds
    scaffold: Color(0xFFF8FAFC), // slate-50
    surface: Color(0xFFFFFFFF), // white
    surfaceHover: Color(0xFFF1F5F9), // slate-100
    surfaceSecondary: Color(0xFFF1F5F9), // slate-100
    surfaceTertiary: Color(0xFFE2E8F0), // slate-200
    // Borders
    border: Color(0xFFE2E8F0), // slate-200
    borderSubtle: Color(0xFFF1F5F9), // slate-100
    borderFocused: Color(0xFF2563EB), // blue-600
    // Text
    textPrimary: Color(0xFF0F172A), // slate-900
    textSecondary: Color(0xFF475569), // slate-600
    textTertiary: Color(0xFF94A3B8), // slate-400
    textInverse: Color(0xFFFFFFFF), // white
    // Accent
    accent: Color(0xFF2563EB), // blue-600
    accentHover: Color(0xFF1D4ED8), // blue-700
    accentSubtle: Color(0xFFDBEAFE), // blue-100
    accentOnAccent: Color(0xFFFFFFFF), // white
    // Status
    success: Color(0xFF16A34A), // green-600
    successSubtle: Color(0xFFDCFCE7), // green-100
    error: Color(0xFFDC2626), // red-600
    errorSubtle: Color(0xFFFEE2E2), // red-100
    warning: Color(0xFFCA8A04), // yellow-600
    warningSubtle: Color(0xFFFEF9C3), // yellow-100
    // Semantic
    codeBackground: Color(0xFFF1F5F9), // slate-100
    overlay: Color(0x40000000), // black 25%
    divider: Color(0xFFE2E8F0), // slate-200
    shimmer: Color(0xFFF1F5F9), // slate-100
  );

  @override
  AppColors copyWith({
    Color? scaffold,
    Color? surface,
    Color? surfaceHover,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? border,
    Color? borderSubtle,
    Color? borderFocused,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? accent,
    Color? accentHover,
    Color? accentSubtle,
    Color? accentOnAccent,
    Color? success,
    Color? successSubtle,
    Color? error,
    Color? errorSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? codeBackground,
    Color? overlay,
    Color? divider,
    Color? shimmer,
  }) {
    return AppColors(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderFocused: borderFocused ?? this.borderFocused,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      accentOnAccent: accentOnAccent ?? this.accentOnAccent,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      error: error ?? this.error,
      errorSubtle: errorSubtle ?? this.errorSubtle,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      codeBackground: codeBackground ?? this.codeBackground,
      overlay: overlay ?? this.overlay,
      divider: divider ?? this.divider,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceTertiary: Color.lerp(surfaceTertiary, other.surfaceTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderFocused: Color.lerp(borderFocused, other.borderFocused, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      accentOnAccent: Color.lerp(accentOnAccent, other.accentOnAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSubtle: Color.lerp(errorSubtle, other.errorSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }
}

/// Convenience extension on [BuildContext] for quick access to [AppColors].
extension AppColorsExtension on BuildContext {
  AppColors get appColors => AppColors.of(this);
}
