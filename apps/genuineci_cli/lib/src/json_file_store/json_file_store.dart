import 'dart:convert';
import 'dart:io';

class JsonFileStore<T> {
  final String filePath;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T data) toJson;

  const JsonFileStore({
    required this.filePath,
    required this.fromJson,
    required this.toJson,
  });

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
}
