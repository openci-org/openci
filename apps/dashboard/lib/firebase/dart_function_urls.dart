/// URL builder for Dart Firebase Functions deployed as Cloud Run services.
///
/// Dart functions use `httpsCallableFromUrl` instead of `httpsCallable`
/// because name-based lookup is not supported for Dart-based functions.
/// See: https://github.com/firebase/firebase-functions-dart#note
///
/// The Cloud Run URL pattern is:
///   https://{service-name}-{project-hash}-{region-code}.a.run.app
///
/// Confirmed via:
///   gcloud run services list --region asia-northeast1 --project openci-b1b91
const _projectHash = 'zmg24bcsaq';
const _regionCode = 'an'; // asia-northeast1

/// Returns the Cloud Run HTTPS URL for a Dart Firebase Function.
///
/// [serviceName] is the kebab-case name as shown in `gcloud run services list`.
/// Example: `dartFunctionUrl('asc-list-apps')`
///   → `https://asc-list-apps-zmg24bcsaq-an.a.run.app`
String dartFunctionUrl(String serviceName) {
  return 'https://$serviceName-$_projectHash-$_regionCode.a.run.app';
}
