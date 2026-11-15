/// A released Firebase Hosting preview and its server-reported expiry.
class FirebaseHostingPreview {
  const FirebaseHostingPreview({required this.url, required this.expiresAt});

  /// The URL serving the released preview.
  final Uri url;

  /// Firebase's actual channel expiration time in UTC, refreshed before release.
  final DateTime expiresAt;
}
