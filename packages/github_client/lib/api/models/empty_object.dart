// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'empty_object.freezed.dart';
part 'empty_object.g.dart';

/// An object without any properties.
@Freezed()
abstract class EmptyObject with _$EmptyObject {
  const factory EmptyObject() = _EmptyObject;
  
  factory EmptyObject.fromJson(Map<String, Object?> json) => _$EmptyObjectFromJson(json);
}
