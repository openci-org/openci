import 'dart:async';

import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workflow/list/github_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectBranchBottomSheet extends ConsumerWidget {
  const SelectBranchBottomSheet({super.key, required this.repoFullName});

  final String repoFullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(gitHubBranchesProvider(repoFullName));
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: asyncErrorWidget,
      data: (user) {
        final currentBranch = user.selectedBranch;

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Text(
                'Select Branch',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: branches.when(
                  data: (branchList) {
                    if (branchList.isEmpty) {
                      return Center(
                        child: Text(
                          'No branches found.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: branchList.length,
                      itemBuilder: (context, index) {
                        final branch = branchList[index];
                        final isSelected = currentBranch == branch;
                        return ListTile(
                          leading: FaIcon(
                            FontAwesomeIcons.codeBranch,
                            size: 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(
                            branch,
                            style: isSelected
                                ? TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, size: 20)
                              : null,
                          onTap: () {
                            unawaited(
                              ref
                                  .read(userProvider.notifier)
                                  .updateSelectedBranch(branch),
                            );
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                  error: asyncErrorWidget,
                  loading: () => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
