import 'package:freezed_annotation/freezed_annotation.dart';

part 'genuine_ci_file.freezed.dart';
part 'genuine_ci_file.g.dart';

@freezed
abstract class GenuineCIFile with _$GenuineCIFile {
  const factory GenuineCIFile({
    required String name,
    required String path,
    required String content,
  }) = _GenuineCIFile;

  factory GenuineCIFile.fromJson(Map<String, dynamic> json) =>
      _$GenuineCIFileFromJson(json);
}
