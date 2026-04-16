// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tree.freezed.dart';
part 'tree.g.dart';

@Freezed()
abstract class Tree with _$Tree {
  const factory Tree({
    required String sha,
    required String url,
  }) = _Tree;
  
  factory Tree.fromJson(Map<String, Object?> json) => _$TreeFromJson(json);
}
