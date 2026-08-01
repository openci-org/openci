import 'package:flutter/material.dart';
import 'package:openci_shared/openci_shared.dart';

Widget cicdJobStatus(BuildJobStatus status) => switch (status) {
  BuildJobStatus.SUCCESS => Icon(
    Icons.check,
    color: Colors.green,
    size: 20,
  ),
  BuildJobStatus.FAILURE ||
  BuildJobStatus.CANCELLED ||
  BuildJobStatus.TIMED_OUT => Icon(
    Icons.close,
    color: Colors.red,
    size: 20,
  ),
  _ => Transform.scale(
    scale: 0.8,
    child: CircularProgressIndicator.adaptive(),
  ),
};
