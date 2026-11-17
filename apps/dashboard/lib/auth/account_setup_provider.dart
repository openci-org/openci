import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Authentication can succeed before the first team's creation succeeds. Run
// setup for restored sessions too, and keep every route behind its completion.
final accountSetupProvider = FutureProvider<void>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) return;
  await ref.read(teamServiceProvider).ensureInitialTeam(user.uid);
}, retry: (_, _) => null);
