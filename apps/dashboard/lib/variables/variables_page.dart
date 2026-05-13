import 'package:dashboard/environment_variables/environment_variables_page.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class VariablesPage extends HookWidget {
  const VariablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.variables.title),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: t.variables.envVarsTab),
            Tab(text: t.variables.secretsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          EnvironmentVariablesTab(),
          SecretManagerTab(),
        ],
      ),
    );
  }
}

/// A body-only version of [VariablesPage] for embedding in a parent tab.
class VariablesBody extends HookWidget {
  const VariablesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2);

    return Column(
      children: [
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: t.variables.envVarsTab),
            Tab(text: t.variables.secretsTab),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: const [
              EnvironmentVariablesTab(),
              SecretManagerTab(),
            ],
          ),
        ),
      ],
    );
  }
}
