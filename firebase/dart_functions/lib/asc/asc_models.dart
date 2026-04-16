/// App Store Connect API model classes.
///
/// These are minimal models containing only the fields
/// that OpenCI actually uses, parsed from the JSON:API
/// response format.

/// An app from App Store Connect.
class AscApp {
  const AscApp({
    required this.id,
    required this.name,
    required this.bundleId,
    this.sku,
  });

  factory AscApp.fromJsonApi(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>;
    return AscApp(
      id: json['id'] as String,
      name: attrs['name'] as String,
      bundleId: attrs['bundleId'] as String,
      sku: attrs['sku'] as String?,
    );
  }

  final String id;
  final String name;
  final String bundleId;
  final String? sku;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bundleId': bundleId,
        'sku': sku,
      };
}

/// A build from App Store Connect.
class AscBuild {
  const AscBuild({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.platform,
    this.uploadedDate,
    this.processingState,
    this.iconUrl,
    this.externalBuildState,
    this.internalBuildState,
    this.appStoreState,
  });

  /// Parses a build from JSON:API format with included resources.
  factory AscBuild.fromJsonApi(
    Map<String, dynamic> json, {
    Map<String, Map<String, dynamic>> preReleaseVersions = const {},
    Map<String, Map<String, dynamic>> buildBetaDetails = const {},
    Map<String, Map<String, dynamic>> appStoreVersions = const {},
  }) {
    final attrs = json['attributes'] as Map<String, dynamic>;
    final relationships =
        json['relationships'] as Map<String, dynamic>? ?? {};

    final preReleaseVersionId =
        _relationshipId(relationships, 'preReleaseVersion');
    final betaDetailId = _relationshipId(relationships, 'buildBetaDetail');
    final appStoreVersionId =
        _relationshipId(relationships, 'appStoreVersion');

    final preRelease =
        preReleaseVersionId != null ? preReleaseVersions[preReleaseVersionId] : null;
    final betaDetail =
        betaDetailId != null ? buildBetaDetails[betaDetailId] : null;
    final appStoreVersion =
        appStoreVersionId != null ? appStoreVersions[appStoreVersionId] : null;

    // Icon URL template replacement
    String? iconUrl;
    final iconToken = attrs['iconAssetToken'] as Map<String, dynamic>?;
    if (iconToken != null) {
      final template = iconToken['templateUrl'] as String?;
      if (template != null) {
        iconUrl = template
            .replaceAll('{w}', '64')
            .replaceAll('{h}', '64')
            .replaceAll('{f}', 'png');
      }
    }

    return AscBuild(
      id: json['id'] as String,
      version: (preRelease?['version'] as String?) ??
          (attrs['version'] as String?) ??
          '',
      buildNumber: (attrs['version'] as String?) ?? '',
      platform: (preRelease?['platform'] as String?) ?? 'IOS',
      uploadedDate: attrs['uploadedDate'] as String?,
      processingState: attrs['processingState'] as String?,
      iconUrl: iconUrl,
      externalBuildState: betaDetail?['externalBuildState'] as String?,
      internalBuildState: betaDetail?['internalBuildState'] as String?,
      appStoreState: appStoreVersion?['appStoreState'] as String?,
    );
  }

  final String id;
  final String version;
  final String buildNumber;
  final String platform;
  final String? uploadedDate;
  final String? processingState;
  final String? iconUrl;
  final String? externalBuildState;
  final String? internalBuildState;
  final String? appStoreState;

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'buildNumber': buildNumber,
        'platform': platform,
        'uploadedDate': uploadedDate,
        'processingState': processingState,
        'iconUrl': iconUrl,
        'externalBuildState': externalBuildState,
        'internalBuildState': internalBuildState,
        'appStoreState': appStoreState,
      };
}

/// A beta group from App Store Connect.
class AscBetaGroup {
  const AscBetaGroup({
    required this.id,
    required this.name,
    required this.isInternalGroup,
  });

  factory AscBetaGroup.fromJsonApi(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>;
    return AscBetaGroup(
      id: json['id'] as String,
      name: attrs['name'] as String,
      isInternalGroup: attrs['isInternalGroup'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final bool isInternalGroup;
}

/// Extracts a relationship ID from JSON:API relationships.
String? _relationshipId(
  Map<String, dynamic> relationships,
  String key,
) {
  final rel = relationships[key] as Map<String, dynamic>?;
  final data = rel?['data'] as Map<String, dynamic>?;
  return data?['id'] as String?;
}

/// Parses the `included` array from a JSON:API response into maps
/// keyed by type.
({
  Map<String, Map<String, dynamic>> preReleaseVersions,
  Map<String, Map<String, dynamic>> buildBetaDetails,
  Map<String, Map<String, dynamic>> appStoreVersions,
}) parseIncludedResources(List<dynamic> included) {
  final preReleaseVersions = <String, Map<String, dynamic>>{};
  final buildBetaDetails = <String, Map<String, dynamic>>{};
  final appStoreVersions = <String, Map<String, dynamic>>{};

  for (final item in included) {
    final map = item as Map<String, dynamic>;
    final type = map['type'] as String;
    final id = map['id'] as String;
    final attrs = map['attributes'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'preReleaseVersions':
        preReleaseVersions[id] = attrs;
      case 'buildBetaDetails':
        buildBetaDetails[id] = attrs;
      case 'appStoreVersions':
        appStoreVersions[id] = attrs;
    }
  }

  return (
    preReleaseVersions: preReleaseVersions,
    buildBetaDetails: buildBetaDetails,
    appStoreVersions: appStoreVersions,
  );
}
