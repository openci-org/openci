// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_context_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GitContext)
final gitContextProvider = GitContextProvider._();

final class GitContextProvider
    extends $NotifierProvider<GitContext, GitContextState> {
  GitContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitContextHash();

  @$internal
  @override
  GitContext create() => GitContext();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitContextState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitContextState>(value),
    );
  }
}

String _$gitContextHash() => r'1c288c69a6004804e3690360f5bbc9d2d60f8e61';

abstract class _$GitContext extends $Notifier<GitContextState> {
  GitContextState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GitContextState, GitContextState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GitContextState, GitContextState>,
              GitContextState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(gitBranches)
final gitBranchesProvider = GitBranchesProvider._();

final class GitBranchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitBranch>>,
          List<GitBranch>,
          FutureOr<List<GitBranch>>
        >
    with $FutureModifier<List<GitBranch>>, $FutureProvider<List<GitBranch>> {
  GitBranchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitBranchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitBranchesHash();

  @$internal
  @override
  $FutureProviderElement<List<GitBranch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitBranch>> create(Ref ref) {
    return gitBranches(ref);
  }
}

String _$gitBranchesHash() => r'72ab96d44a2817a8713362fca7537a7af11864fc';

@ProviderFor(gitCommits)
final gitCommitsProvider = GitCommitsFamily._();

final class GitCommitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitCommit>>,
          List<GitCommit>,
          FutureOr<List<GitCommit>>
        >
    with $FutureModifier<List<GitCommit>>, $FutureProvider<List<GitCommit>> {
  GitCommitsProvider._({
    required GitCommitsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gitCommitsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitCommitsHash();

  @override
  String toString() {
    return r'gitCommitsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GitCommit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitCommit>> create(Ref ref) {
    final argument = this.argument as String;
    return gitCommits(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GitCommitsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitCommitsHash() => r'60aecfd68049d7086ffca26261c79f249d2626b2';

final class GitCommitsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GitCommit>>, String> {
  GitCommitsFamily._()
    : super(
        retry: null,
        name: r'gitCommitsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GitCommitsProvider call(String branch) =>
      GitCommitsProvider._(argument: branch, from: this);

  @override
  String toString() => r'gitCommitsProvider';
}
