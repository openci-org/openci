import 'package:freezed_annotation/freezed_annotation.dart';

part 'genuine_ci_file.freezed.dart';
part 'genuine_ci_file.g.dart';

@freezed
abstract class GenuineCiFile with _$GenuineCiFile {
  const factory GenuineCiFile({
    required String name,
    required String path,
    required String content,
  }) = _GenuineCiFile;

  factory GenuineCiFile.fromJson(Map<String, dynamic> json) =>
      _$GenuineCiFileFromJson(json);
}
