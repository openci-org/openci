// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_integration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GitHubIntegration)
const gitHubIntegrationProvider = GitHubIntegrationProvider._();

final class GitHubIntegrationProvider
    extends $AsyncNotifierProvider<GitHubIntegration, bool> {
  const GitHubIntegrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubIntegrationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubIntegrationHash();

  @$internal
  @override
  GitHubIntegration create() => GitHubIntegration();
}

String _$gitHubIntegrationHash() => r'92578372012bb3d20d7b4cdb7a1b15e14d4d4386';

abstract class _$GitHubIntegration extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
