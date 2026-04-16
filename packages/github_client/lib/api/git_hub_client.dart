// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'apps/apps_client.dart';
import 'repos/repos_client.dart';
import 'checks/checks_client.dart';

/// GitHub v3 REST API `v1.1.4`.
///
/// GitHub's v3 REST API.
class GitHubClient {
  GitHubClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.1.4';

  AppsClient? _apps;
  ReposClient? _repos;
  ChecksClient? _checks;

  AppsClient get apps => _apps ??= AppsClient(_dio, baseUrl: _baseUrl);

  ReposClient get repos => _repos ??= ReposClient(_dio, baseUrl: _baseUrl);

  ChecksClient get checks => _checks ??= ChecksClient(_dio, baseUrl: _baseUrl);
}
