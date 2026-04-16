// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'annotations2.dart';
import 'images2.dart';

part 'output2.freezed.dart';
part 'output2.g.dart';

@Freezed()
abstract class Output2 with _$Output2 {
  const factory Output2({
    /// Can contain Markdown.
    required String summary,

    /// **Required**.
    String? title,

    /// Can contain Markdown.
    String? text,

    /// Adds information from your analysis to specific lines of code. Annotations are visible in GitHub's pull request UI. Annotations are visible in GitHub's pull request UI. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about annotations in the UI, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
    List<Annotations2>? annotations,

    /// Adds images to the output displayed in the GitHub pull request UI.
    List<Images2>? images,
  }) = _Output2;

  factory Output2.fromJson(Map<String, Object?> json) =>
      _$Output2FromJson(json);
}
