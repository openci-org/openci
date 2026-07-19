import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/team_provider.dart';
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
    final installationIdsController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedTeamId = useState<String?>(null);
    final isLoading = useState(false);
    final teamT = t.team;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: teamListStream.when(
        data: (teams) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // ── Team selector ──
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: teams.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final isSelected = selectedTeamId.value == team.id;

                    return InkWell(
                      onTap: () {
                        selectedTeamId.value = team.id;
                        teamNameController.text = team.name;
                        githubBaseUrlController.text = team.githubBaseUrl ?? '';
                        installationIdsController.text = team.installationIds
                            .map((id) => id.toString())
                            .join(', ');
                      },
                      hoverColor: colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                      splashColor: colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
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
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.15,
                                      )
                                    : colorScheme.surfaceContainerHighest,
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
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withValues(
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
                                      ? colorScheme.primary
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // ── Rename field ──
              if (selectedTeamId.value != null) ...[
                const SizedBox(height: 16),
                Form(
                  key: formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: TextFormField(
                      controller: teamNameController,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: teamT.newTeamName,
                        hintStyle: TextStyle(
                          color: colorScheme.outline,
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
                            color: colorScheme.outline,
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
                      foregroundColor: colorScheme.onPrimary,
                      backgroundColor: colorScheme.primary,
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
                                    githubBaseUrl: githubBaseUrlController.text,
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
                              color: colorScheme.onPrimary,
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
          );
        },
        error: asyncErrorWidget,
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.outline,
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
