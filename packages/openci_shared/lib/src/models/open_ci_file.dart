import 'package:freezed_annotation/freezed_annotation.dart';

part 'open_ci_file.freezed.dart';
part 'open_ci_file.g.dart';

@freezed
abstract class OpenCIFile with _$OpenCIFile {
  const factory OpenCIFile({
    required String name,
    required String path,
    required String content,
  }) = _OpenCIFile;

  factory OpenCIFile.fromJson(Map<String, dynamic> json) =>
      _$OpenCIFileFromJson(json);
}
