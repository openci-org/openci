import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final class SentryProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag(
          'provider',
          context.provider.name ?? context.provider.runtimeType.toString(),
        );
      },
    );
    super.providerDidFail(context, error, stackTrace);
  }
}
