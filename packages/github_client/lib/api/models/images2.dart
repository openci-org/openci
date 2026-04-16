// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'images2.freezed.dart';
part 'images2.g.dart';

@Freezed()
abstract class Images2 with _$Images2 {
  const factory Images2({
    /// The alternative text for the image.
    required String alt,

    /// The full URL of the image.
    @JsonKey(name: 'image_url')
    required String imageUrl,

    /// A short image description.
    String? caption,
  }) = _Images2;
  
  factory Images2.fromJson(Map<String, Object?> json) => _$Images2FromJson(json);
}
