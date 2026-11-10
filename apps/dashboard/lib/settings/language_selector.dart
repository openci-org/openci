import 'package:dashboard/app_locale_provider.dart';
import 'package:dashboard/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LanguageSelector extends HookConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePreferenceProvider);
    final isSaving = useState(false);
    final selected = locale?.languageCode ?? 'system';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: context.t.language.label,
        prefixIcon: const Icon(Icons.language),
        enabled: !isSaving.value,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: 'system',
              child: Text(context.t.language.system),
            ),
            const DropdownMenuItem(value: 'en', child: Text('English')),
            const DropdownMenuItem(value: 'ja', child: Text('日本語')),
          ],
          onChanged: isSaving.value
              ? null
              : (value) async {
                  if (value == null) return;
                  isSaving.value = true;
                  try {
                    await ref
                        .read(localePreferenceProvider.notifier)
                        .setLocale(
                          value == 'system'
                              ? null
                              : AppLocaleUtils.parse(value),
                        );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t.language.saveFailed)),
                    );
                  } finally {
                    if (context.mounted) isSaving.value = false;
                  }
                },
        ),
      ),
    );
  }
}
