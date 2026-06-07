import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ChipStatus {
  queued,
  inProgress,
  fail,
  success,
  cancelled,
  skipped
  ;

  Color get backgroundColor => switch (this) {
    ChipStatus.queued => const Color(0xFFF4F7FF),
    ChipStatus.inProgress => const Color(0xFFEAF2FF),
    ChipStatus.fail => const Color(0xFFFEEBEC),
    ChipStatus.success => const Color(0xFFEAF7EF),
    ChipStatus.cancelled => const Color(0xFFFFF4DF),
    ChipStatus.skipped => const Color(0xFFF2F4F7),
  };

  Color get borderColor => switch (this) {
    ChipStatus.queued => const Color(0xFFD8E2FF),
    ChipStatus.inProgress => const Color(0xFFC7DBFF),
    ChipStatus.fail => const Color(0xFFF7C5CB),
    ChipStatus.success => const Color(0xFFCBEAD8),
    ChipStatus.cancelled => const Color(0xFFFADFAF),
    ChipStatus.skipped => const Color(0xFFD0D5DD),
  };

  Color get foregroundColor => switch (this) {
    ChipStatus.queued => const Color(0xFF4E5BA6),
    ChipStatus.inProgress => const Color(0xFF2563EB),
    ChipStatus.fail => const Color(0xFFDC2626),
    ChipStatus.success => const Color(0xFF16865A),
    ChipStatus.cancelled => const Color(0xFFD97706),
    ChipStatus.skipped => const Color(0xFF667085),
  };

  IconData get icon => switch (this) {
    ChipStatus.queued => Icons.schedule_rounded,
    ChipStatus.inProgress => Icons.play_arrow_rounded,
    ChipStatus.fail => Icons.close_rounded,
    ChipStatus.success => Icons.check_rounded,
    ChipStatus.cancelled => Icons.block_rounded,
    ChipStatus.skipped => Icons.skip_next_rounded,
  };
}

class StatusIcon extends StatelessWidget {
  const StatusIcon({super.key, required this.status});

  final ChipStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == ChipStatus.inProgress) {
      return CupertinoActivityIndicator(
        color: status.foregroundColor,
        radius: 5,
      );
    }

    return Icon(status.icon, size: 10);
  }
}
