List<String> parseLumeServerUrls(String? urlsStr) {
  if (urlsStr == null) {
    return [];
  }
  return urlsStr
      .split(',')
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();
}
