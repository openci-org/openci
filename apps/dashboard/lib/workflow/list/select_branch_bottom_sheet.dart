import 'dart:async';

import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/workflow/list/github_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ── Design Tokens (ui.sh) ──
const _cardBg = Color(0xFF18181B);
const _cardBorder = Color(0xFF27272A);
const _accentBlue = Color(0xFF3B82F6);
const _textPrimary = Color(0xFFFAFAFA);
const _textSecondary = Color(0xFFA1A1AA);
const _textTertiary = Color(0xFF71717A);
const _radius = 12.0;

class SelectBranchBottomSheet extends ConsumerWidget {
  const SelectBranchBottomSheet({super.key, required this.repoFullName});

  final String repoFullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.codeBranch,
                            size: 24,
                            color: _textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          wfT.noBranches,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Scrollbar(
                child: ListView.separated(
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        wfT.selectBranchHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: _cardBorder, height: 20),
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
        borderRadius: BorderRadius.circular(_radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _accentBlue.withValues(alpha: 0.06) : _cardBg,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: isSelected ? _accentBlue : _cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.codeBranch,
                size: 14,
                color: isSelected ? _accentBlue : _textTertiary,
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
                    color: isSelected ? _accentBlue : _textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentBlue,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
