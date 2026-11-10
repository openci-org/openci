import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_firebase_auth.dart';
import 'package:dashboard/deep_link/deep_link_listener.dart';
import 'package:dashboard/router/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Root extends ConsumerWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(deepLinkListenerProvider);
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final app = TooltipVisibility(
          visible: false,
          child: authState.when(
            skipLoadingOnRefresh: false,
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (_, _) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.t.auth.stateError,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.invalidate(connectionFirebaseAuthProvider);
                          ref.invalidate(activeConnectionProfileProvider);
                          ref.invalidate(authStateChangesProvider);
                        },
                        child: Text(context.t.common.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (_) => child ?? const SizedBox.shrink(),
          ),
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
