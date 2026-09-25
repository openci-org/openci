import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/cicd_log/detail/ci_cd_log_detail_page.dart';
import 'package:dashboard/root/dashboard_root.dart';
import 'package:dashboard/router/custom_transitions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier(0);
  // Refresh after the future used by redirect receives the latest auth event.
  ref.listen(authStateChangesProvider.future, (_, _) {
    refreshNotifier.value++;
  });
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
        pageBuilder: (context, state) {
          final buildJobId = state.pathParameters['buildJobId']!;
          return FastBottomSheetPage(
            key: state.pageKey,
            child: CicdLogDetailRoutePage(buildJobId: buildJobId),
          );
        },
      ),
    ],
    redirect: (context, state) async {
      final user = await ref.read(authStateChangesProvider.future);
      final isAuthed = user != null;
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
