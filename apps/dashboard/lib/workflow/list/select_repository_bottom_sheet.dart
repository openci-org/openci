import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/app_strings.dart';

import 'package:dashboard/users/user_provider.dart';

import 'package:dashboard/utilities/async_error_widget.dart';

import 'package:dashboard/workflow/list/github_repository_provider.dart';

import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:skeletonizer/skeletonizer.dart';



class SelectRepositoryBottomSheet extends HookConsumerWidget {
  const SelectRepositoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repos = ref.watch(gitHubRepositoriesProvider);
    final searchController = useTextEditingController();
    final searchText = useValueListenable(searchController).text;
    final wfT = t.workflow;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: AppColors.of(context).accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wfT.selectRepository,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      Text(
                        wfT.selectRepositoryHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.of(context).border, height: 16),
          ),

          // ── Search ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: AppColors.of(context).textPrimary),
              decoration: InputDecoration(
                hintText: wfT.searchRepositories,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.of(context).textTertiary.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.of(context).textTertiary,
                ),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 16,
                          color: AppColors.of(context).textTertiary,
                        ),
                        onPressed: () => searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.of(context).surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.of(context).border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.of(context).border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.of(context).accent,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── List ──
          Expanded(
            child: repos.when(
              data: (repositories) {
                if (repositories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.of(context).surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.of(context).border),
                            ),
                            child: Icon(
                              Icons.folder_off_outlined,
                              size: 24,
                              color: AppColors.of(context).textTertiary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            wfT.noRepositories,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.of(context).textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 40,
                            color: AppColors.of(context).textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            wfT.noMatchingRepositories(query: query),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.of(context).textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      final repo = filtered[index];
                      return _RepoTile(
                        fullName: repo.fullName,
                        defaultBranch: repo.defaultBranch,
                        isPrivate: repo.private,
                        onTap: () {
                          Navigator.of(context).pop();
                          ref
                              .read(userProvider.notifier)
                              .updateSelectedRepository(
                                repository: repo.fullName,
                                defaultBranch: repo.defaultBranch,
                              );
                        },
                      );
                    },
                  );
              },
              error: asyncErrorWidget,
              loading: () => Skeletonizer(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) => _RepoTile(
                    fullName: 'owner/repository-name-$index',
                    defaultBranch: 'main',
                    isPrivate: false,
                    onTap: null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoTile extends StatelessWidget {
  const _RepoTile({
    required this.fullName,
    required this.defaultBranch,
    required this.isPrivate,
    required this.onTap,
  });

  final String fullName;
  final String defaultBranch;
  final bool isPrivate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Row(
            children: [
              FaIcon(
                isPrivate ? FontAwesomeIcons.lock : FontAwesomeIcons.globe,
                size: 14,
                color: isPrivate ? Colors.amber : AppColors.of(context).textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.workflow.defaultBranch(branch: defaultBranch),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.of(context).textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
