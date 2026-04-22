import 'package:dashboard/theme/app_colors.dart';
import 'dart:async';


import 'package:dashboard/i18n/strings.g.dart';

import 'package:dashboard/users/user_provider.dart';

import 'package:dashboard/utilities/async_error_widget.dart';

import 'package:dashboard/workflow/list/github_repository_provider.dart';

import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:skeletonizer/skeletonizer.dart';



class SelectBranchBottomSheet extends HookConsumerWidget {
  const SelectBranchBottomSheet({super.key, required this.repoFullName});

  final String repoFullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final branches = ref.watch(gitHubBranchesProvider(repoFullName));
    final userAsync = ref.watch(userProvider);
    final wfT = t.workflow;

    return userAsync.when(
      loading: () => _buildShell(
        context,
        wfT,
        child: Skeletonizer(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, index) => _BranchTile(
              branchName: 'branch-name-$index',
              isSelected: false,
              onTap: null,
            ),
          ),
        ),
      ),
      error: asyncErrorWidget,
      data: (user) {
        final currentBranch = user.selectedBranch;

        return _buildShell(
          context,
          wfT,
          child: branches.when(
            data: (branchList) {
              if (branchList.isEmpty) {
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
                          child: FaIcon(
                            FontAwesomeIcons.codeBranch,
                            size: 24,
                            color: AppColors.of(context).textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          wfT.noBranches,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Scrollbar(
                controller: scrollController,
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: branchList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final branch = branchList[index];
                    final isSelected = currentBranch == branch;
                    return _BranchTile(
                      branchName: branch,
                      isSelected: isSelected,
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
                ),
              );
            },
            error: asyncErrorWidget,
            loading: () => Skeletonizer(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, index) => _BranchTile(
                  branchName: 'branch-name-$index',
                  isSelected: false,
                  onTap: null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShell(
    BuildContext context,
    dynamic wfT, {
    required Widget child,
  }) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
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
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: const FaIcon(
                      FontAwesomeIcons.codeBranch,
                      size: 14,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wfT.selectBranch,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      Text(
                        wfT.selectBranchHint,
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
            child: Divider(color: AppColors.of(context).border, height: 20),
          ),
          // ── Content ──
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({
    required this.branchName,
    required this.isSelected,
    required this.onTap,
  });

  final String branchName;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.of(context).accent.withValues(alpha: 0.06) : AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? AppColors.of(context).accent : AppColors.of(context).border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.codeBranch,
                size: 14,
                color: isSelected ? AppColors.of(context).accent : AppColors.of(context).textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  branchName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? AppColors.of(context).accent : AppColors.of(context).textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.of(context).accent,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
