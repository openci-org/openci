import 'dart:async';

import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_detail_page.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/build_logs/app_distributions_page.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/notifications/notification_provider.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/team/accept_invitation_page.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workers/worker_status_page.dart';
import 'package:dashboard/workflow/list/workflow_list_page.dart';
import 'package:dashboard/workflow/list/workflows_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
        pageBuilder: (context, state) => _responsivePage(
          key: state.pageKey,
          child: const AuthPage(),
        ),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) =>
            state.uri.path == '/' ? '/workspace' : null,
        routes: [
          GoRoute(
            path: 'workspace',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const WorkspaceRoutePage(),
            ),
          ),
          GoRoute(
            path: 'runs',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const AuthenticatedScaffoldRoutePage(
                title: 'CI/CDログ',
                child: LogsBody(),
              ),
            ),
          ),
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
            path: 'workflows',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const WorkflowsPage(),
            ),
          ),
          GoRoute(
            path: 'variables',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const AuthenticatedScaffoldRoutePage(
                title: 'シークレット',
                child: VariablesBody(),
              ),
            ),
          ),
          GoRoute(
            path: 'store-release',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const AuthenticatedScaffoldRoutePage(
                title: 'Store Release',
                child: StoreReleaseBody(),
              ),
            ),
          ),
          GoRoute(
            path: 'distributions',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const AuthenticatedScaffoldRoutePage(
                title: 'アプリ配信',
                child: AppDistributionsBody(),
              ),
            ),
          ),
          GoRoute(
            path: 'workers',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const AuthenticatedScaffoldRoutePage(
                title: 'Workers',
                child: WorkerStatusBody(),
              ),
            ),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (context, state) => _responsivePage(
              key: state.pageKey,
              child: const AuthenticatedScaffoldRoutePage(
                title: '設定',
                child: SettingsPage(),
              ),
            ),
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
          return redirectTarget == '/' ? '/workspace' : redirectTarget;
        }
        return '/workspace';
      }
      return null;
    },
  );
});

/// デスクトップ幅（>800px）ではフェードアニメーション、
/// モバイル幅ではMaterialの標準ページ遷移を使用する
Page<void> _responsivePage({
  required LocalKey key,
  required Widget child,
}) {
  // WidgetsBindingで画面幅を取得（BuildContext外で判定するため）
  final width =
      WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .physicalSize
          .width /
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

  return MaterialPage<void>(key: key, child: child);
}

class WorkspaceRoutePage extends HookConsumerWidget {
  const WorkspaceRoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.asData?.value;
    final configAsync = ref.watch(selfHostedConfigProvider);
    final configReadyForData = configAsync.maybeWhen(
      data: (_) => true,
      orElse: () => false,
    );

    useEffect(() {
      if (user != null && configReadyForData) {
        ref.read(notificationServiceProvider);
      }
      return null;
    }, [user?.uid, configReadyForData]);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthPage();
        }
        return configAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          ),
          error: asyncErrorWidget,
          data: (_) {
            return const WorkspacePage();
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
    );
  }
}

class AuthenticatedScaffoldRoutePage extends ConsumerWidget {
  const AuthenticatedScaffoldRoutePage({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

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
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(
              tooltip: 'ダッシュボードに戻る',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/workspace'),
            ),
          ),
          body: child,
        );
      },
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
                  child: Text('ビルドジョブが見つかりません'),
                ),
              );
            }

            if (MediaQuery.sizeOf(context).width >= buildLogsSplitViewBreakpoint) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('CI/CDログ'),
                  leading: IconButton(
                    tooltip: 'ダッシュボードに戻る',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/workspace'),
                  ),
                ),
                body: LogsBody(initialBuildJobId: buildJobId),
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
