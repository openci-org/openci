import 'dart:convert';

import 'package:dashboard/app_strings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

enum SelfHostedSetupAction { manual }

Future<SelfHostedSetupAction?> showSelfHostedSetup(BuildContext context) {
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<SelfHostedSetupAction>(
      context: context,
      builder: (_) => const Dialog(child: SelfHostedSetupForm()),
    );
  }
  return showModalBottomSheet<SelfHostedSetupAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: const SelfHostedSetupForm(),
    ),
  );
}

class SelfHostedSetupForm extends HookWidget {
  const SelfHostedSetupForm({super.key});

  @override
  Widget build(BuildContext context) {
    final formT = t.auth.firebaseForm;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final apiUrl = useTextEditingController();
    final name = useTextEditingController();
    // Retain only display metadata in this UI preview, never the private key.
    final account =
        useState<({String fileName, String projectId, String email})?>(null);
    final fileError = useState<String?>(null);
    final isPicking = useState(false);
    final isReviewing = useState(false);

    void clearAccount() {
      if (name.text == account.value?.projectId) name.clear();
      account.value = null;
      fileError.value = null;
    }

    Future<void> pickAccount() async {
      isPicking.value = true;
      try {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          withData: true,
        );
        if (!context.mounted || result == null || result.files.isEmpty) return;
        final file = result.files.single;
        final bytes = file.bytes ?? await file.xFile.readAsBytes();
        if (!context.mounted) return;
        final json = jsonDecode(utf8.decode(bytes));
        if (json is! Map<String, dynamic> ||
            json['type'] != 'service_account' ||
            ['project_id', 'client_email', 'private_key'].any(
              (key) =>
                  json[key] is! String || (json[key] as String).trim().isEmpty,
            )) {
          throw const FormatException();
        }
        final projectId = (json['project_id'] as String).trim();
        if (name.text.trim().isEmpty || name.text == account.value?.projectId) {
          name.text = projectId;
        }
        account.value = (
          fileName: file.name,
          projectId: projectId,
          email: (json['client_email'] as String).trim(),
        );
        fileError.value = null;
      } catch (_) {
        if (!context.mounted) return;
        clearAccount();
        // Parser/platform errors can contain file contents. Do not display them.
        fileError.value = formT.invalidServiceAccount;
      } finally {
        if (context.mounted) isPicking.value = false;
      }
    }

    final selected = account.value;
    final profileName = name.text.trim().isEmpty
        ? selected?.projectId ?? ''
        : name.text.trim();

    return SizedBox(
      width: 560,
      height: 720,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isReviewing.value ? formT.reviewTitle : formT.title,
                      style: textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: t.common.close,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(isReviewing.value),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(formT.setupSubtitle, style: textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          formT.setupPreview,
                          style: textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isReviewing.value && selected != null) ...[
                        _SetupDetail(
                          label: formT.profileName,
                          value: profileName,
                        ),
                        _SetupDetail(
                          label: formT.apiUrl,
                          value: apiUrl.text.trim(),
                        ),
                        _SetupDetail(
                          label: formT.projectId,
                          value: selected.projectId,
                        ),
                        _SetupDetail(
                          label: formT.serviceAccount,
                          value: selected.email,
                        ),
                        const Divider(height: 32),
                        Text(formT.setupPlatforms, style: textTheme.titleSmall),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('iOS')),
                            Chip(label: Text('macOS')),
                            Chip(label: Text('Android')),
                            Chip(label: Text('Web')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formT.setupExplanation,
                          style: textTheme.bodyMedium,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: apiUrl,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: formT.apiUrl,
                            hintText: 'https://api.example.com',
                            helperText: formT.apiUrlHint,
                            helperMaxLines: 2,
                            errorMaxLines: 2,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            final uri = Uri.tryParse(text);
                            if (uri == null ||
                                !['http', 'https'].contains(uri.scheme) ||
                                uri.host.isEmpty ||
                                RegExp(r'\s').hasMatch(text)) {
                              return formT.invalidApiUrl;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(formT.serviceAccount, style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: isPicking.value ? null : pickAccount,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          icon: isPicking.value
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(
                            selected == null
                                ? formT.selectServiceAccount
                                : formT.replaceServiceAccount,
                          ),
                        ),
                        if (selected != null)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              selected.fileName,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(selected.projectId),
                            trailing: IconButton(
                              tooltip: formT.removeServiceAccount,
                              onPressed: isPicking.value ? null : clearAccount,
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        if (fileError.value != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              fileError.value!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          formT.serviceAccountHint,
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: name,
                          decoration: InputDecoration(
                            labelText: formT.optionalProfileName,
                            hintText: formT.profileNameHint,
                            helperText: formT.automaticProfileName,
                            helperMaxLines: 2,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        formT.credentialsNotSaved,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isReviewing.value) ...[
                    FilledButton(
                      onPressed: null,
                      child: Text(formT.startSetup),
                    ),
                    TextButton(
                      onPressed: () => isReviewing.value = false,
                      child: Text(formT.editSetup),
                    ),
                  ] else
                    FilledButton(
                      onPressed: isPicking.value
                          ? null
                          : () {
                              final valid = formKey.currentState!.validate();
                              if (account.value == null) {
                                fileError.value = formT.serviceAccountRequired;
                              }
                              if (!valid || account.value == null) return;
                              FocusScope.of(context).unfocus();
                              isReviewing.value = true;
                            },
                      child: Text(formT.reviewSetup),
                    ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, SelfHostedSetupAction.manual),
                    child: Text(formT.manualSetup),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupDetail extends StatelessWidget {
  const _SetupDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
