import 'package:dashboard/deep_link/deep_link_listener.dart';
import 'package:dashboard/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
