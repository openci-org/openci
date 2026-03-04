// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repository_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubRepo _$GitHubRepoFromJson(Map<String, dynamic> json) => _GitHubRepo(
  fullName: json['fullName'] as String,
  name: json['name'] as String,
  owner: json['owner'] as String,
  private: json['private'] as bool,
  defaultBranch: json['defaultBranch'] as String,
);

Map<String, dynamic> _$GitHubRepoToJson(_GitHubRepo instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'name': instance.name,
      'owner': instance.owner,
      'private': instance.private,
      'defaultBranch': instance.defaultBranch,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitHubRepositories)
final gitHubRepositoriesProvider = GitHubRepositoriesProvider._();

final class GitHubRepositoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitHubRepo>>,
          List<GitHubRepo>,
          FutureOr<List<GitHubRepo>>
        >
    with $FutureModifier<List<GitHubRepo>>, $FutureProvider<List<GitHubRepo>> {
  GitHubRepositoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubRepositoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubRepositoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<GitHubRepo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitHubRepo>> create(Ref ref) {
    return gitHubRepositories(ref);
  }
}

String _$gitHubRepositoriesHash() =>
    r'a0cbb56861c96d15f7498dec9de0e84609da5a8e';

@ProviderFor(gitHubBranches)
final gitHubBranchesProvider = GitHubBranchesFamily._();

final class GitHubBranchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  GitHubBranchesProvider._({
    required GitHubBranchesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gitHubBranchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubBranchesHash();

  @override
  String toString() {
    return r'gitHubBranchesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return gitHubBranches(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GitHubBranchesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubBranchesHash() => r'4087f0c94e8fb56e3f2041bcfadf22ab812d35dc';

final class GitHubBranchesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  GitHubBranchesFamily._()
    : super(
        retry: null,
        name: r'gitHubBranchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GitHubBranchesProvider call(String repoFullName) =>
      GitHubBranchesProvider._(argument: repoFullName, from: this);

  @override
  String toString() => r'gitHubBranchesProvider';
}

@ProviderFor(SelectedRepository)
final selectedRepositoryProvider = SelectedRepositoryProvider._();

final class SelectedRepositoryProvider
    extends $NotifierProvider<SelectedRepository, String?> {
  SelectedRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedRepositoryHash();

  @$internal
  @override
  SelectedRepository create() => SelectedRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedRepositoryHash() =>
    r'70b05028453786086f5ac137b5f855ae3b47073e';

abstract class _$SelectedRepository extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedBranch)
final selectedBranchProvider = SelectedBranchProvider._();

final class SelectedBranchProvider
    extends $NotifierProvider<SelectedBranch, String?> {
  SelectedBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedBranchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedBranchHash();

  @$internal
  @override
  SelectedBranch create() => SelectedBranch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedBranchHash() => r'ebbb6f5a1361c1afaf15398cc2677f4ba3ef3d38';

abstract class _$SelectedBranch extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
