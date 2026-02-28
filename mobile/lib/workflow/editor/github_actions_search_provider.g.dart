// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_actions_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(searchGitHubActions)
final searchGitHubActionsProvider = SearchGitHubActionsFamily._();

final class SearchGitHubActionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitHubAction>>,
          List<GitHubAction>,
          FutureOr<List<GitHubAction>>
        >
    with
        $FutureModifier<List<GitHubAction>>,
        $FutureProvider<List<GitHubAction>> {
  SearchGitHubActionsProvider._({
    required SearchGitHubActionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'searchGitHubActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchGitHubActionsHash();

  @override
  String toString() {
    return r'searchGitHubActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GitHubAction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitHubAction>> create(Ref ref) {
    final argument = this.argument as String;
    return searchGitHubActions(ref, query: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchGitHubActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchGitHubActionsHash() =>
    r'711f5811897a2a5673ed18d6964cff947a45ef41';

final class SearchGitHubActionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GitHubAction>>, String> {
  SearchGitHubActionsFamily._()
    : super(
        retry: null,
        name: r'searchGitHubActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchGitHubActionsProvider call({required String query}) =>
      SearchGitHubActionsProvider._(argument: query, from: this);

  @override
  String toString() => r'searchGitHubActionsProvider';
}
