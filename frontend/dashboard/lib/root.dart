import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/navigation_bar_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/workflow/editor/workflow_editor_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStreamProvider = StreamProvider(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

const _tabPageList = [
  WorkflowEditorPage(),
  SettingsPage(),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStreamProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          return AuthPage();
        }
        return NavigationBarPage(_tabPageList);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
