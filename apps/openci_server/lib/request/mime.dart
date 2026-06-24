String getContentType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  return switch (ext) {
    'ipa' => 'application/octet-stream',
    'zip' => 'application/zip',
    'xml' => 'application/xml',
    'plist' => 'application/xml',
    _ => 'application/octet-stream',
  };
}
