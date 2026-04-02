import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Root extends ConsumerWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          color: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ).surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: ColorScheme.fromSeed(
                seedColor: Colors.blue,
              ).outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
        ),
        dividerTheme: DividerThemeData(
          color: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ).outlineVariant.withValues(alpha: 0.5),
          space: 1,
          thickness: 1,
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
      ),
    );
  }
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
