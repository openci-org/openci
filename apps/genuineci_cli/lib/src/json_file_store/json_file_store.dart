import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as p;

import '../extensions/file_extensions.dart';

class JsonFileStore<T> {
  const JsonFileStore({
    required this.filePath,
    required this.fromJson,
    required this.toJson,
  });

  static String defaultPath(
    String fileName, {
    String productName = 'genuineci',
  }) {
    final homeDir = applicationConfigHome(productName);
    return p.join(homeDir, fileName);
  }

  final String filePath;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T data) toJson;

  Future<T?> get() async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      throw FormatException('File at $filePath is empty.');
    }

    final dynamic json = jsonDecode(content);
    if (json is! Map<String, dynamic>) {
      throw FormatException('Invalid JSON format in file at $filePath.');
    }

    return fromJson(json);
  }

  Future<void> set(T data, {bool chmod600 = false}) async {
    final file = File(filePath);
    await file.writeAsStringAtomic(
      jsonEncode(toJson(data)),
      chmod600: chmod600,
    );
  }
}
