// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'annotations.dart';
import 'images.dart';

part 'output.freezed.dart';
part 'output.g.dart';

@Freezed()
abstract class Output with _$Output {
  const factory Output({
    /// The title of the check run.
    required String title,

    /// The summary of the check run. This parameter supports Markdown. **Maximum length**: 65535 characters.
    required String summary,

    /// The details of the check run. This parameter supports Markdown. **Maximum length**: 65535 characters.
    String? text,

    /// Adds information from your analysis to specific lines of code. Annotations are visible on GitHub in the **Checks** and **Files changed** tab of the pull request. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about how you can view annotations on GitHub, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
    List<Annotations>? annotations,

    /// Adds images to the output displayed in the GitHub pull request UI.
    List<Images>? images,
  }) = _Output;

  factory Output.fromJson(Map<String, Object?> json) => _$OutputFromJson(json);
}
