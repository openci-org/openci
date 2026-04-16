// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final content =
      '''// This file is auto-generated before each build.
// Run: dart run tool/update_build_info.dart

const buildDate = '$dateStr';
''';

  File('lib/build_info.dart').writeAsStringSync(content);
  print('Updated build_info.dart → buildDate = $dateStr');
}
