import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

class NotificationSettingsSection extends ConsumerWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final userAsync = ref.watch(userProvider);
    return Text("mock");

    // return userAsync.when(
    //   data: (user) => _NotificationSettingsContent(
    //     currentPreference: user.notificationPreference,
    //   ),
    //   loading: () => const SizedBox(
    //     height: 100,
    //     child: Center(child: CircularProgressIndicator.adaptive()),
    //   ),
    //   error: asyncErrorWidget,
    // );
  }
}

// class _NotificationSettingsContent extends ConsumerWidget {
//   const _NotificationSettingsContent({required this.currentPreference});

//   final NotificationPreference currentPreference;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//           child: Row(
//             children: [
//               Icon(
//                 Symbols.notifications_rounded,
//                 size: 20,
//                 color: theme.colorScheme.primary,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Build Notifications',
//                 style: theme.textTheme.titleSmall?.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: theme.colorScheme.primary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 4),
//         _NotificationOptionTile(
//           title: 'All',
//           subtitle: 'Notify on both success and failure',
//           icon: Symbols.notifications_active_rounded,
//           isSelected: currentPreference == NotificationPreference.all,
//           onTap: () => _updatePreference(
//             context,
//             ref,
//             NotificationPreference.all,
//           ),
//         ),
//         _NotificationOptionTile(
//           title: 'Success Only',
//           subtitle: 'Notify only when build succeeds',
//           icon: Symbols.check_circle_rounded,
//           iconColor: Colors.green,
//           isSelected: currentPreference == NotificationPreference.successOnly,
//           onTap: () => _updatePreference(
//             context,
//             ref,
//             NotificationPreference.successOnly,
//           ),
//         ),
//         _NotificationOptionTile(
//           title: 'Failure Only',
//           subtitle: 'Notify only when build fails',
//           icon: Symbols.error_rounded,
//           iconColor: Colors.redAccent,
//           isSelected: currentPreference == NotificationPreference.failureOnly,
//           onTap: () => _updatePreference(
//             context,
//             ref,
//             NotificationPreference.failureOnly,
//           ),
//         ),
//         _NotificationOptionTile(
//           title: 'None',
//           subtitle: 'Do not send any notifications',
//           icon: Symbols.notifications_off_rounded,
//           iconColor: Colors.grey,
//           isSelected: currentPreference == NotificationPreference.none,
//           onTap: () => _updatePreference(
//             context,
//             ref,
//             NotificationPreference.none,
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _updatePreference(
//     BuildContext context,
//     WidgetRef ref,
//     NotificationPreference preference,
//   ) async {
//     if (preference == currentPreference) return;
//     try {
//       await ref
//           .read(userProvider.notifier)
//           .updateNotificationPreference(preference);
//       if (!context.mounted) return;
//       context.showSnackBarMessage(
//         'Notification preference updated',
//       );
//     } catch (e) {
//       if (!context.mounted) return;
//       context.showSnackBarMessage(
//         'Failed to update: $e',
//       );
//     }
//   }
// }

class _NotificationOptionTile extends StatelessWidget {
  const _NotificationOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? (iconColor ?? theme.colorScheme.primary)
            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
