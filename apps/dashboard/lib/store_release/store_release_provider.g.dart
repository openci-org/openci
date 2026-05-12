// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_release_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether ASC API credentials are configured for the current team.

@ProviderFor(IsAscConfigured)
final isAscConfiguredProvider = IsAscConfiguredProvider._();

/// Whether ASC API credentials are configured for the current team.
final class IsAscConfiguredProvider
    extends $StreamNotifierProvider<IsAscConfigured, bool> {
  /// Whether ASC API credentials are configured for the current team.
  IsAscConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAscConfiguredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAscConfiguredHash();

  @$internal
  @override
  IsAscConfigured create() => IsAscConfigured();
}

String _$isAscConfiguredHash() => r'2fb815f059cbbc9b7b49503b70483ed44e83bf0d';

/// Whether ASC API credentials are configured for the current team.

abstract class _$IsAscConfigured extends $StreamNotifier<bool> {
  Stream<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetch the list of apps from App Store Connect.

@ProviderFor(AscApps)
final ascAppsProvider = AscAppsProvider._();

/// Fetch the list of apps from App Store Connect.
final class AscAppsProvider
    extends $AsyncNotifierProvider<AscApps, List<AscApp>> {
  /// Fetch the list of apps from App Store Connect.
  AscAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ascAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ascAppsHash();

  @$internal
  @override
  AscApps create() => AscApps();
}

String _$ascAppsHash() => r'ee0d153df209a5cd6040e78697057bb9cc00398c';

/// Fetch the list of apps from App Store Connect.

abstract class _$AscApps extends $AsyncNotifier<List<AscApp>> {
  FutureOr<List<AscApp>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<AscApp>>, List<AscApp>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AscApp>>, List<AscApp>>,
              AsyncValue<List<AscApp>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetch builds for a specific app.

@ProviderFor(AscBuilds)
final ascBuildsProvider = AscBuildsFamily._();

/// Fetch builds for a specific app.
final class AscBuildsProvider
    extends $AsyncNotifierProvider<AscBuilds, List<AscBuild>> {
  /// Fetch builds for a specific app.
  AscBuildsProvider._({
    required AscBuildsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ascBuildsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ascBuildsHash();

  @override
  String toString() {
    return r'ascBuildsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AscBuilds create() => AscBuilds();

  @override
  bool operator ==(Object other) {
    return other is AscBuildsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ascBuildsHash() => r'd84a480db2d9575d2c8ce8f9c67f479aaea9b615';

/// Fetch builds for a specific app.

final class AscBuildsFamily extends $Family
    with
        $ClassFamilyOverride<
          AscBuilds,
          AsyncValue<List<AscBuild>>,
          List<AscBuild>,
          FutureOr<List<AscBuild>>,
          String
        > {
  AscBuildsFamily._()
    : super(
        retry: null,
        name: r'ascBuildsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetch builds for a specific app.

  AscBuildsProvider call(String appId) =>
      AscBuildsProvider._(argument: appId, from: this);

  @override
  String toString() => r'ascBuildsProvider';
}

/// Fetch builds for a specific app.

abstract class _$AscBuilds extends $AsyncNotifier<List<AscBuild>> {
  late final _$args = ref.$arg as String;
  String get appId => _$args;

  FutureOr<List<AscBuild>> build(String appId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<AscBuild>>, List<AscBuild>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AscBuild>>, List<AscBuild>>,
              AsyncValue<List<AscBuild>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Submit a build to TestFlight (external beta testing).

@ProviderFor(SubmitToTestFlight)
final submitToTestFlightProvider = SubmitToTestFlightProvider._();

/// Submit a build to TestFlight (external beta testing).
final class SubmitToTestFlightProvider
    extends $AsyncNotifierProvider<SubmitToTestFlight, void> {
  /// Submit a build to TestFlight (external beta testing).
  SubmitToTestFlightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitToTestFlightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitToTestFlightHash();

  @$internal
  @override
  SubmitToTestFlight create() => SubmitToTestFlight();
}

String _$submitToTestFlightHash() =>
    r'da24b1a41f6cbdc3c128341714ce7a513726c647';

/// Submit a build to TestFlight (external beta testing).

abstract class _$SubmitToTestFlight extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Submit a build for App Store Review.

@ProviderFor(SubmitForReview)
final submitForReviewProvider = SubmitForReviewProvider._();

/// Submit a build for App Store Review.
final class SubmitForReviewProvider
    extends $AsyncNotifierProvider<SubmitForReview, void> {
  /// Submit a build for App Store Review.
  SubmitForReviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitForReviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitForReviewHash();

  @$internal
  @override
  SubmitForReview create() => SubmitForReview();
}

String _$submitForReviewHash() => r'f2f68931158d36aff51409f96ae774a7e5c6b58e';

/// Submit a build for App Store Review.

abstract class _$SubmitForReview extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Setup ASC API credentials.

@ProviderFor(SetupAscCredentials)
final setupAscCredentialsProvider = SetupAscCredentialsProvider._();

/// Setup ASC API credentials.
final class SetupAscCredentialsProvider
    extends $AsyncNotifierProvider<SetupAscCredentials, void> {
  /// Setup ASC API credentials.
  SetupAscCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setupAscCredentialsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setupAscCredentialsHash();

  @$internal
  @override
  SetupAscCredentials create() => SetupAscCredentials();
}

String _$setupAscCredentialsHash() =>
    r'3ea372cae78329dfe685587ff010a6999a8fa5b8';

/// Setup ASC API credentials.

abstract class _$SetupAscCredentials extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
