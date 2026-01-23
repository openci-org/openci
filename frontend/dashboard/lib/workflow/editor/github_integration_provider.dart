import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_integration_provider.g.dart';

@riverpod
class GitHubIntegration extends _$GitHubIntegration {
  @override
  Future<bool> build() {
    return Future.value(false);
  }
}
