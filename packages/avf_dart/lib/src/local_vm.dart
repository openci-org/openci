class LocalVM {
  final String name;
  final String path;
  final int diskSizeBytes;
  final int diskSizeUsedBytes;
  final DateTime created;

  LocalVM({
    required this.name,
    required this.path,
    required this.diskSizeBytes,
    required this.diskSizeUsedBytes,
    required this.created,
  });
}
