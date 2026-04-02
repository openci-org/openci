import 'dart:async';

import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/notifications/notification_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workflow/list/workflow_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  final refreshNotifier = RouterRefreshNotifier(
    authNotifier.getFirebaseAuth().authStateChanges(),
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => SwipeablePage(
          key: state.pageKey,
          builder: (context) => const AuthPage(),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => SwipeablePage(
          key: state.pageKey,
          builder: (context) => const HomeRoutePage(),
        ),
      ),
      GoRoute(
        path: '/runs/:buildJobId',
        pageBuilder: (context, state) {
          final buildJobId = state.pathParameters['buildJobId']!;
          return SwipeablePage(
            key: state.pageKey,
            builder: (context) =>
                BuildLogsDetailRoutePage(buildJobId: buildJobId),
          );
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final isAuthed = authState.asData?.value != null;
      final onAuthRoute = state.matchedLocation == '/auth';

      if (!isAuthed && !onAuthRoute) return '/auth';
      if (isAuthed && onAuthRoute) return '/';
      return null;
    },
  );
});

class HomeRoutePage extends HookConsumerWidget {
  const HomeRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.asData?.value;

    useEffect(() {
      if (user != null) {
        ref.read(notificationServiceProvider);
      }
      return null;
    }, [user?.uid]);

    return authState.when(
      data: (_) => const WorkflowListPage(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
    );
  }
}

class BuildLogsDetailRoutePage extends ConsumerWidget {
  const BuildLogsDetailRoutePage({
    super.key,
    required this.buildJobId,
  });

  final String buildJobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: Text('Build job not found'),
            ),
          );
        }
        return BuildLogsDetailPage(buildJob: buildJob);
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
