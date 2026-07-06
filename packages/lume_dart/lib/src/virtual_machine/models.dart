import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class LumeDiskSize with _$LumeDiskSize {
  const factory LumeDiskSize({required int allocated, required int total}) =
      _LumeDiskSize;

  factory LumeDiskSize.fromJson(Map<String, dynamic> json) =>
      _$LumeDiskSizeFromJson(json);
}

@freezed
abstract class LumeVM with _$LumeVM {
  const factory LumeVM({
    required String name,
    required String status,
    String? ipAddress,
    bool? sshAvailable,
    int? cpuCount,
    int? memorySize,
    String? display,
    String? networkMode,
    String? os,
    String? locationName,
    String? vncUrl,
    LumeDiskSize? diskSize,
  }) = _LumeVM;

  factory LumeVM.fromJson(Map<String, dynamic> json) => _$LumeVMFromJson(json);
}
