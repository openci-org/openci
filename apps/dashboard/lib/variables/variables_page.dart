import 'package:dashboard/environment_variables/environment_variables_page.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class VariablesPage extends HookWidget {
  const VariablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 2);
    useListenable(tabController);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.variables.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: List.generate(2, (index) {
                final labels = [
                  t.variables.envVarsTab,
                  t.variables.secretsTab,
                ];
                final isSelected = tabController.index == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => tabController.animateTo(index),
                      hoverColor: Colors.white.withValues(alpha: 0.04),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
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
