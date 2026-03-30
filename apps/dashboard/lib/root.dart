import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/navigation_bar_page.dart';
import 'package:dashboard/notifications/notification_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    useEffect(() {
      if (user != null) {
        ref.read(notificationServiceProvider);
      }
      return null;
    }, [user?.uid]);

    return authState.when(
      data: (user) {
        if (user == null) {
          return AuthPage();
        }

        return NavigationBarPage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
    );
  }
}
