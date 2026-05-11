import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/update/page_reloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class UpdateAvailableBanner extends HookWidget {
  const UpdateAvailableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isVisible = useState(true);

    if (!isVisible.value) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final isCompact = MediaQuery.sizeOf(context).width < 640;

    return Align(
      alignment: isCompact ? Alignment.bottomCenter : Alignment.bottomRight,
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          isCompact ? 12 : 24,
          12,
          isCompact ? 12 : 24,
          20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.accentSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      color: colors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '新しいバージョンがあります',
                          style: textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '最新の機能と修正を反映するには、ページを更新してください。',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: superReloadPage,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('更新する'),
                            ),
                            TextButton(
                              onPressed: () {
                                isVisible.value = false;
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('あとで'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: colors.textTertiary,
                    onPressed: () {
                      isVisible.value = false;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
