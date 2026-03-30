// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_actions_provider.dart';

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
    required ({String query, String teamId}) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<GitHubAction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitHubAction>> create(Ref ref) {
    final argument = this.argument as ({String query, String teamId});
    return searchGitHubActions(
      ref,
      query: argument.query,
      teamId: argument.teamId,
    );
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
    r'441cf36fcb67be9f05007574f814bbafffd80580';

final class SearchGitHubActionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<GitHubAction>>,
          ({String query, String teamId})
        > {
  SearchGitHubActionsFamily._()
    : super(
        retry: null,
        name: r'searchGitHubActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchGitHubActionsProvider call({
    required String query,
    required String teamId,
  }) => SearchGitHubActionsProvider._(
    argument: (query: query, teamId: teamId),
    from: this,
  );

  @override
  String toString() => r'searchGitHubActionsProvider';
}

@ProviderFor(actionInputs)
final actionInputsProvider = ActionInputsFamily._();

final class ActionInputsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ActionInput>>,
          List<ActionInput>,
          FutureOr<List<ActionInput>>
        >
    with
        $FutureModifier<List<ActionInput>>,
        $FutureProvider<List<ActionInput>> {
  ActionInputsProvider._({
    required ActionInputsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'actionInputsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$actionInputsHash();

  @override
  String toString() {
    return r'actionInputsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ActionInput>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ActionInput>> create(Ref ref) {
    final argument = this.argument as String;
    return actionInputs(ref, actionRef: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActionInputsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$actionInputsHash() => r'92973ebbae426a49f2a2a68482fa84f5648b63c4';

final class ActionInputsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ActionInput>>, String> {
  ActionInputsFamily._()
    : super(
        retry: null,
        name: r'actionInputsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActionInputsProvider call({required String actionRef}) =>
      ActionInputsProvider._(argument: actionRef, from: this);

  @override
  String toString() => r'actionInputsProvider';
}

@ProviderFor(actionTags)
final actionTagsProvider = ActionTagsFamily._();

final class ActionTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  ActionTagsProvider._({
    required ActionTagsFamily super.from,
    required ({String fullName, String teamId}) super.argument,
  }) : super(
         retry: null,
         name: r'actionTagsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$actionTagsHash();

  @override
  String toString() {
    return r'actionTagsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as ({String fullName, String teamId});
    return actionTags(
      ref,
      fullName: argument.fullName,
      teamId: argument.teamId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActionTagsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$actionTagsHash() => r'9b31e74f621471a8642ef53c1103e24179ab8b49';

final class ActionTagsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<String>>,
          ({String fullName, String teamId})
        > {
  ActionTagsFamily._()
    : super(
        retry: null,
        name: r'actionTagsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActionTagsProvider call({required String fullName, required String teamId}) =>
      ActionTagsProvider._(
        argument: (fullName: fullName, teamId: teamId),
        from: this,
      );

  @override
  String toString() => r'actionTagsProvider';
}
