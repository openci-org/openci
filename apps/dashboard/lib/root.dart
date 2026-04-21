import 'package:dashboard/deep_link/deep_link_listener.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class Root extends ConsumerWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deepLinkListenerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      theme: _buildTheme(),
    );
  }
}

ThemeData _buildTheme() {
  // ── Dark-first color scheme for CI/CD developer tool ──
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6), // Tailwind blue-500
    brightness: Brightness.dark,
  );

  // Inter-based text theme for readability (monospace only for code/logs)
  final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  return ThemeData(
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Near-black background
    textTheme: baseTextTheme,
    // ── Card — slightly lighter than bg, subtle inset ring, no shadow ──
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    // ── Divider — opacity-based (uidotsh: never solid colors) ──
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.08),
      space: 1,
      thickness: 1,
    ),
    // ── AppBar — clean, no shadow, dark surface ──
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: const Color(0xFF0A0A0A),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: baseTextTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.2,
      ),
    ),
    // ── Input fields — dark surface, subtle border, clean focus ring ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF141414),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: colorScheme.error,
        ),
      ),
      labelStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 14,
      ),
    ),
    // ── Filled button — primary action, no shadow ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    ),
    // ── Elevated button — secondary action, no shadow ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    ),
    // ── Outlined button — subtle border ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    ),
    // ── Text button ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    ),
    // ── TabBar — clean tabs, subtle divider ──
    tabBarTheme: TabBarThemeData(
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.5),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.white.withValues(alpha: 0.06),
    ),
    // ── BottomSheet — dark surface ──
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),
    // ── Snackbar ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF141414),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    ),
    // ── PopupMenu ──
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    ),
    // ── Chip ──
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.08),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    // ── FloatingActionButton ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    // ── Checkbox ──
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    // ── Page transitions ──
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ResponsivePageTransitionsBuilder(),
        TargetPlatform.iOS: ResponsivePageTransitionsBuilder(),
        TargetPlatform.macOS: ResponsivePageTransitionsBuilder(),
        TargetPlatform.windows: ResponsivePageTransitionsBuilder(),
        TargetPlatform.linux: ResponsivePageTransitionsBuilder(),
      },
    ),
  );
}

class ResponsivePageTransitionsBuilder extends PageTransitionsBuilder {
  const ResponsivePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 画面幅が800pxを超える（デスクトップサイズ）場合は、素早いフェードアニメーション
    if (MediaQuery.sizeOf(context).width > 800) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          // MaterialPageRouteのデフォルト遷移時間(300ms)のうち、最初の約100msでフェードインを完了させる
          curve: const Interval(0.0, 0.33, curve: Curves.easeOut),
        ),
        child: child,
      );
    }

    // モバイルサイズの場合はプラットフォーム標準のアニメーション
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return const CupertinoPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return const ZoomPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
