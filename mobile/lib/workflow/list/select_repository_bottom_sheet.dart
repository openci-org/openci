import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workflow/list/github_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectRepositoryBottomSheet extends HookConsumerWidget {
  const SelectRepositoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repos = ref.watch(gitHubRepositoriesProvider);
    final searchController = useTextEditingController();
    final searchText = useValueListenable(searchController).text;
    final isLoading = useState(false);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Text(
            'Select Repository',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search repositories...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading.value)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator.adaptive(),
            ),
          Expanded(
            child: repos.when(
              data: (repositories) {
                if (repositories.isEmpty) {
                  return Center(
                    child: Text(
                      'No repositories found.\nPlease install the OpenCI GitHub App.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }
                final query = searchText.toLowerCase();
                final filtered = query.isEmpty
                    ? repositories
                    : repositories
                          .where(
                            (r) => r.fullName.toLowerCase().contains(query),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No repositories matching "$query"',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final repo = filtered[index];
                    return ListTile(
                      leading: Icon(
                        repo.private
                            ? FontAwesomeIcons.lock
                            : FontAwesomeIcons.globe,
                        size: 16,
                      ),
                      title: Text(repo.fullName),
                      subtitle: Text('default: ${repo.defaultBranch}'),
                      onTap: () async {
                        isLoading.value = true;
                        await ref
                            .read(userProvider.notifier)
                            .updateSelectedRepository(
                              repository: repo.fullName,
                              defaultBranch: repo.defaultBranch,
                            );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
              error: asyncErrorWidget,
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
            ),
          ),
        ],
      ),
    );
  }
}

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
                          leading: Icon(
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
                          onTap: () async {
                            await ref
                                .read(userProvider.notifier)
                                .updateSelectedBranch(branch);
                            if (!context.mounted) return;
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
