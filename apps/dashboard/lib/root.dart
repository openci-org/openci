import 'package:dashboard/deep_link/deep_link_listener.dart';
import 'package:dashboard/router.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/themes/tab_bar_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _compactTextScale = 0.94;

class Root extends ConsumerWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deepLinkListenerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ja', 'JP'),
      supportedLocales: const [Locale('ja', 'JP')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      theme: _buildTheme(),
      builder: (context, child) {
        final app = TooltipVisibility(
          visible: false,
          child: child ?? const SizedBox.shrink(),
        );
        if (!kDebugMode) return app;
        return Banner(
          message: 'DEBUG',
          location: BannerLocation.topStart,
          child: app,
        );
      },
    );
  }
}

ThemeData _buildTheme() {
  const colors = AppColors.light;
  final accentStateLayer = colors.accent.withValues(alpha: 0.08);
  final accentContainer = colors.accent.withValues(alpha: 0.10);
  final accentContainerForeground = colors.accentHover;

  final generatedColorScheme = ColorScheme.fromSeed(
    seedColor: colors.accent,
    brightness: Brightness.light,
  );
  final colorScheme = generatedColorScheme.copyWith(
    primary: colors.accent,
    onPrimary: colors.accentOnAccent,
    primaryContainer: accentContainer,
    onPrimaryContainer: accentContainerForeground,
    secondary: colors.accentHover,
    onSecondary: colors.accentOnAccent,
    secondaryContainer: accentContainer,
    onSecondaryContainer: accentContainerForeground,
    tertiary: colors.textSecondary,
    onTertiary: colors.surface,
    tertiaryContainer: colors.surfaceSecondary,
    onTertiaryContainer: colors.textPrimary,
    surfaceTint: Colors.transparent,
  );

  final baseMaterialTheme = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: Brightness.light,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
  final baseTextTheme = _scaledTextTheme(baseMaterialTheme.textTheme);

  return ThemeData(
    extensions: [colors],
    colorScheme: colorScheme,
    brightness: Brightness.light,
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    scaffoldBackgroundColor: colors.scaffold,
    textTheme: baseTextTheme,
    focusColor: accentStateLayer,
    hoverColor: colors.accent.withValues(alpha: 0.05),
    highlightColor: accentStateLayer,
    splashColor: accentStateLayer,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.accent,
      selectionColor: colors.accent.withValues(alpha: 0.18),
      selectionHandleColor: colors.accent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: colors.divider,
      space: 1,
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: colors.scaffold,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: baseTextTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.borderFocused, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.error),
      ),
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: colors.textTertiary,
        fontSize: 14,
      ),
    ),
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
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: colors.border),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    ),
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
    tabBarTheme: tabBarThemeData,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E293B),
      contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: const Color(0xFF60A5FA),
      disabledActionTextColor: Colors.white.withValues(alpha: 0.4),
      closeIconColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceHover,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceHover,
      side: BorderSide(color: colors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
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

TextTheme _scaledTextTheme(TextTheme theme) {
  return theme.copyWith(
    displayLarge: _scaledTextStyle(theme.displayLarge),
    displayMedium: _scaledTextStyle(theme.displayMedium),
    displaySmall: _scaledTextStyle(theme.displaySmall),
    headlineLarge: _scaledTextStyle(theme.headlineLarge),
    headlineMedium: _scaledTextStyle(theme.headlineMedium),
    headlineSmall: _scaledTextStyle(theme.headlineSmall),
    titleLarge: _scaledTextStyle(theme.titleLarge),
    titleMedium: _scaledTextStyle(theme.titleMedium),
    titleSmall: _scaledTextStyle(theme.titleSmall),
    bodyLarge: _scaledTextStyle(theme.bodyLarge),
    bodyMedium: _scaledTextStyle(theme.bodyMedium),
    bodySmall: _scaledTextStyle(theme.bodySmall),
    labelLarge: _scaledTextStyle(theme.labelLarge),
    labelMedium: _scaledTextStyle(theme.labelMedium),
    labelSmall: _scaledTextStyle(theme.labelSmall),
  );
}

TextStyle? _scaledTextStyle(TextStyle? style) {
  final fontSize = style?.fontSize;
  if (style == null || fontSize == null) {
    return style;
  }
  return style.copyWith(fontSize: fontSize * _compactTextScale);
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
    if (MediaQuery.sizeOf(context).width > 800) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.33, curve: Curves.easeOut),
        ),
        child: child,
      );
    }

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
