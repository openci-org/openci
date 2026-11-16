/// The outcome of a request to publish one package version to pub.dev.
enum PubPublishStatus {
  /// The pub command successfully submitted this version.
  published,

  /// This version existed before publishing was attempted.
  alreadyPublished,
}

class PubPublishResult {
  const PubPublishResult({
    required this.name,
    required this.version,
    required this.status,
  });

  final String name;
  final String version;
  final PubPublishStatus status;

  Uri get url => Uri.https('pub.dev', '/packages/$name/versions/$version');
}
