import 'package:flutter/material.dart';
import 'package:openci_shared/openci_shared.dart';

Widget jobStatusIcon(BuildStep step, ThemeData theme) => switch (step.status) {
  BuildJobStatus.SUCCESS => const Icon(
    Icons.check_circle_rounded,
    color: Colors.green,
    size: 18,
  ),
  BuildJobStatus.FAILURE => const Icon(
    Icons.cancel_rounded,
    color: Colors.red,
    size: 18,
  ),
  BuildJobStatus.IN_PROGRESS => SizedBox(
    width: 14,
    height: 14,
    child: CircularProgressIndicator(
      strokeWidth: 1.5,
      color: theme.colorScheme.primary,
    ),
  ),
  BuildJobStatus.QUEUED => const Icon(
    Icons.schedule_rounded,
    color: Color(0xFFBC8CFF),
    size: 18,
  ),
  BuildJobStatus.CANCELLED => const Icon(
    Icons.block_rounded,
    color: Colors.amber,
    size: 18,
  ),
  BuildJobStatus.WAITING => const Icon(
    Icons.adjust_rounded,
    color: Colors.amberAccent,
    size: 18,
  ),
  BuildJobStatus.SKIPPED => Icon(
    Icons.skip_next_rounded,
    color: theme.colorScheme.outline,
    size: 18,
  ),
  BuildJobStatus.TIMED_OUT => const Icon(
    Icons.timer_off_rounded,
    color: Colors.red,
    size: 18,
  ),
};
