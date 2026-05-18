import 'package:dashboard/app_strings.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:flutter/material.dart';

class VariablesPage extends StatelessWidget {
  const VariablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.variables.title),
      ),
      body: const VariablesBody(),
    );
  }
}

/// A body-only version of [VariablesPage] for embedding in a parent tab.
class VariablesBody extends StatelessWidget {
  const VariablesBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SecretManagerTab();
  }
}
