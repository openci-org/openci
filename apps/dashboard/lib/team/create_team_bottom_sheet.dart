import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateTeamBottomSheet extends HookConsumerWidget {
  const CreateTeamBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamNameController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final teamT = t.team;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
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
                  hintText: teamT.teamName,
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
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.group_add_outlined,
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
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.of(context).accentOnAccent,
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
                            .createTeam(teamNameController.text);
                        if (!context.mounted) return;
                        context.showSnackBarMessage(teamT.createdSuccess);
                        Navigator.of(context).pop();
                      } catch (e) {
                        isLoading.value = false;
                        if (!context.mounted) return;
                        context.showSnackBarMessage(e.toString());
                      }
                    },
              child: isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.of(context).accentOnAccent,
                      ),
                    )
                  : Text(
                      teamT.createTeam,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
