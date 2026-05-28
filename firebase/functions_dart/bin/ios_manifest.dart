import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/openci_shared.dart';

String escapeXml(String unsafe) {
  return unsafe
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

Future<Response> iosManifest(Request request, Firebase firebase) async {
  final buildJobId = request.url.queryParameters['buildJobId'];
  if (buildJobId == null || buildJobId.isEmpty) {
    logger.warn('iosManifest request is missing buildJobId query parameter');
    return Response(400, body: 'Missing buildJobId query parameter');
  }

  try {
    final firestore = firebase.adminApp.firestore();
    final docRef = firestore.collection(buildJobsCollection).doc(buildJobId);
    final doc = await docRef.get();

    if (!doc.exists) {
      logger.warn('iosManifest: Build job $buildJobId not found');
      return Response(404, body: 'Build job not found');
    }

    final data = doc.data();
    if (data == null) {
      logger.warn('iosManifest: Build job $buildJobId contains no data');
      return Response(404, body: 'Build job data is empty');
    }

    final job = BuildJob.fromJson(data);

    final now = DateTime.now().toUtc();
    final updatedJob = job.copyWith(
      otaDownloadedAt: now,
      updatedAt: now,
    );
    await docRef.set(updatedJob.toJson());

    final ipaUrl = job.ipaUrl;
    final bundleId = job.bundleId ?? 'org.openci.dashboard';
    final ipaVersion = job.ipaVersion ?? '1.0.0';
    final appName = job.appName ?? 'OpenCI App';

    if (ipaUrl == null || ipaUrl.isEmpty) {
      logger.warn('iosManifest: Build job $buildJobId does not have an ipaUrl');
      return Response(
        400,
        body: 'Build job does not contain a compiled app URL',
      );
    }

    final safeIpaUrl = escapeXml(ipaUrl);
    final safeBundleId = escapeXml(bundleId);
    final safeIpaVersion = escapeXml(ipaVersion);
    final safeAppName = escapeXml(appName);

    final plistXml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>$safeIpaUrl</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>$safeBundleId</string>
        <key>bundle-version</key>
        <string>$safeIpaVersion</string>
        <key>kind</key>
        <string>software</string>
        <key>title</key>
        <string>$safeAppName</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>''';

    return Response(
      200,
      body: plistXml,
      headers: {'Content-Type': 'text/xml; charset=utf-8'},
    );
  } catch (error, stack) {
    logger.error('Failed to generate iosManifest plist: $error\n$stack');
    return Response(500, body: 'Internal Server Error');
  }
}
