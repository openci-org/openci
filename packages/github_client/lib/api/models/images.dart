// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'images.freezed.dart';
part 'images.g.dart';

@Freezed()
abstract class Images with _$Images {
  const factory Images({
    /// The alternative text for the image.
    required String alt,

    /// The full URL of the image.
    @JsonKey(name: 'image_url') required String imageUrl,

    /// A short image description.
    String? caption,
  }) = _Images;

  factory Images.fromJson(Map<String, Object?> json) => _$ImagesFromJson(json);
}
