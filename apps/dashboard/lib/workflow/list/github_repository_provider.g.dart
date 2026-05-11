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
    r'ec53b08bebccb3f6e5c5f0df4a944478d6d7efa5';

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

String _$gitHubBranchesHash() => r'd556b48f60aa59be69c2bc0d9f12451030795c52';

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
