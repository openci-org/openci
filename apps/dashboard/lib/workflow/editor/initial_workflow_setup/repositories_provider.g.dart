// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repositories_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubRepository _$GitHubRepositoryFromJson(Map<String, dynamic> json) =>
    _GitHubRepository(
      fullName: json['fullName'] as String,
      name: json['name'] as String,
      owner: json['owner'] as String,
      private: json['private'] as bool,
      defaultBranch: json['defaultBranch'] as String,
    );

Map<String, dynamic> _$GitHubRepositoryToJson(_GitHubRepository instance) =>
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

@ProviderFor(repositories)
final repositoriesProvider = RepositoriesProvider._();

final class RepositoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitHubRepository>>,
          List<GitHubRepository>,
          FutureOr<List<GitHubRepository>>
        >
    with
        $FutureModifier<List<GitHubRepository>>,
        $FutureProvider<List<GitHubRepository>> {
  RepositoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repositoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repositoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<GitHubRepository>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitHubRepository>> create(Ref ref) {
    return repositories(ref);
  }
}

String _$repositoriesHash() => r'd9ee2adf772a25d30063bd4b8cd3957ae8451fd9';
