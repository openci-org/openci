import 'dart:async';

import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/notifications/notification_provider.dart';
import 'package:dashboard/team/accept_invitation_page.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workflow/list/workflow_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

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
        pageBuilder: (context, state) => _responsivePage(
          key: state.pageKey,
          child: const AuthPage(),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _responsivePage(
          key: state.pageKey,
          child: const HomeRoutePage(),
        ),
        routes: [
          GoRoute(
            path: 'runs/:buildJobId',
            pageBuilder: (context, state) {
              final buildJobId = state.pathParameters['buildJobId']!;
              return _responsivePage(
                key: state.pageKey,
                child: BuildLogsDetailRoutePage(buildJobId: buildJobId),
              );
            },
          ),
          GoRoute(
            path: 'invite/:token',
            pageBuilder: (context, state) {
              final token = state.pathParameters['token']!;
              return _responsivePage(
                key: state.pageKey,
                child: AcceptInvitationPage(token: token),
              );
            },
          ),
        ],
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

/// デスクトップ幅（>800px）ではフェードアニメーション、
/// モバイル幅ではSwipeablePageを使用する
Page<void> _responsivePage({
  required LocalKey key,
  required Widget child,
}) {
  // WidgetsBindingで画面幅を取得（BuildContext外で判定するため）
  final width =
      WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  if (width > 800) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  return SwipeablePage(key: key, builder: (context) => child);
}

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
      data: (user) {
        if (user == null) {
          return const AuthPage();
        }
        return const WorkflowListPage();
      },
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
    final authState = ref.watch(authProvider);

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
                  child: Text('Build job not found'),
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
