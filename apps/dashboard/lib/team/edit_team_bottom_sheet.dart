import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditTeamBottomSheet extends HookConsumerWidget {
  const EditTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamListStream = ref.watch(teamListProvider);
    final teamNameController = useTextEditingController();
    final githubBaseUrlController = useTextEditingController();
    final githubApiBaseUrlController = useTextEditingController();
    final installationIdsController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedTeamId = useState<String?>(null);
    final isLoading = useState(false);
    final teamT = t.team;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxSheetHeight =
        (MediaQuery.sizeOf(context).height - viewInsets.bottom) * 0.9;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: viewInsets.bottom,
        ),
        child: teamListStream.when(
          data: (teams) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      teamT.editTeam,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                  ),
                  // ── Team selector ──
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.of(context).surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: teams.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.of(context).divider,
                        ),
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          final isSelected = selectedTeamId.value == team.id;

                          return InkWell(
                            onTap: () {
                              selectedTeamId.value = team.id;
                              teamNameController.text = team.name;
                              githubBaseUrlController.text =
                                  team.githubBaseUrl ?? '';
                              githubApiBaseUrlController.text =
                                  team.githubApiBaseUrl ?? '';
                              installationIdsController.text = team
                                  .installationIds
                                  .map((id) => id.toString())
                                  .join(', ');
                            },
                            hoverColor: AppColors.of(context).borderSubtle,
                            splashColor: AppColors.of(context).borderSubtle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.of(
                                              context,
                                            ).accent.withValues(alpha: 0.15)
                                          : AppColors.of(
                                              context,
                                            ).surfaceTertiary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        team.name.isNotEmpty
                                            ? team.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.of(context).accent
                                              : AppColors.of(
                                                  context,
                                                ).textPrimary.withValues(
                                                  alpha: 0.6,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      team.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.of(context).accent
                                            : AppColors.of(context).textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppColors.of(context).accent,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // ── Rename field ──
                  if (selectedTeamId.value != null) ...[
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.of(context).border,
                          ),
                        ),
                        child: TextFormField(
                          controller: teamNameController,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.of(context).textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: teamT.newTeamName,
                            hintStyle: TextStyle(
                              color: AppColors.of(context).textTertiary,
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 8,
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.of(context).textTertiary,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return teamT.enterTeamName;
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EnterpriseTextField(
                      controller: githubBaseUrlController,
                      label: 'GitHub Base URL',
                      hintText: 'https://github.ibm.com',
                    ),
                    const SizedBox(height: 8),
                    _EnterpriseTextField(
                      controller: githubApiBaseUrlController,
                      label: 'GitHub API Base URL',
                      hintText: 'https://github.ibm.com/api/v3',
                    ),
                    const SizedBox(height: 8),
                    _EnterpriseTextField(
                      controller: installationIdsController,
                      label: 'Installation IDs',
                      hintText: '123456, 789012',
                      validator: (value) {
                        try {
                          _parseInstallationIds(value ?? '');
                          return null;
                        } on FormatException catch (e) {
                          return e.message;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.of(context).textPrimary,
                          backgroundColor: AppColors.of(context).accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                isLoading.value = true;
                                try {
                                  await ref
                                      .read(teamListProvider.notifier)
                                      .updateTeamName(
                                        selectedTeamId.value!,
                                        teamNameController.text,
                                      );
                                  await ref
                                      .read(teamListProvider.notifier)
                                      .updateGitHubSettings(
                                        teamId: selectedTeamId.value!,
                                        githubBaseUrl:
                                            githubBaseUrlController.text,
                                        githubApiBaseUrl:
                                            githubApiBaseUrlController.text,
                                        installationIds: _parseInstallationIds(
                                          installationIdsController.text,
                                        ),
                                      );
                                  if (!context.mounted) return;
                                  context.showSnackBarMessage(
                                    teamT.updatedSuccess,
                                  );
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  isLoading.value = false;
                                  context.showSnackBarMessage(e.toString());
                                }
                              },
                        child: isLoading.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.of(context).textPrimary,
                                ),
                              )
                            : Text(
                                teamT.editTeam,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          error: asyncErrorWidget,
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
    );
  }
}

class _EnterpriseTextField extends StatelessWidget {
  const _EnterpriseTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.of(context).border,
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.of(context).textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.of(context).textTertiary,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

List<int> _parseInstallationIds(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];

  final ids = <int>[];
  for (final part in trimmed.split(',')) {
    final value = part.trim();
    if (value.isEmpty) continue;
    final id = int.tryParse(value);
    if (id == null) {
      throw const FormatException(
        'Installation IDs must be comma-separated numbers.',
      );
    }
    ids.add(id);
  }
  return ids;
}
