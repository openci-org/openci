import 'dart:async';

import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/root/dashboard_root.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(
    FirebaseAuth.instance.authStateChanges(),
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardRouteGateway(),
      ),
      GoRoute(
        path: '/runs/:buildJobId',
        builder: (context, state) {
          final buildJobId = state.pathParameters['buildJobId']!;
          return BuildLogsDetailRoutePage(buildJobId: buildJobId);
        },
      ),
    ],
    redirect: (context, state) {
      final isAuthed = FirebaseAuth.instance.currentUser != null;
      final onAuthRoute = state.matchedLocation == '/auth';
      final requestedLocation = state.uri.toString();
      final redirectTarget = state.uri.queryParameters['from'];

      if (!isAuthed && !onAuthRoute) {
        final encodedLocation = Uri.encodeComponent(requestedLocation);
        return '/auth?from=$encodedLocation';
      }
      if (isAuthed && onAuthRoute) {
        if (redirectTarget != null && redirectTarget.isNotEmpty) {
          return redirectTarget;
        }
        return '/';
      }
      return null;
    },
  );
});

class BuildLogsDetailRoutePage extends ConsumerWidget {
  const BuildLogsDetailRoutePage({
    super.key,
    required this.buildJobId,
  });

  final String buildJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
      data: (user) {
        if (user == null) {
          return const AuthPage();
        }

        final buildJobAsync = ref.watch(buildJobByIdProvider(buildJobId));
        return buildJobAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          ),
          error: asyncErrorWidget,
          data: (buildJob) {
            if (buildJob == null) {
              return const Scaffold(
                body: Center(
                  child: Text('ビルドジョブが見つかりません'),
                ),
              );
            }

            return BuildLogsDetailPage(buildJob: buildJob);
          },
        );
      },
    );
  }
}

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
