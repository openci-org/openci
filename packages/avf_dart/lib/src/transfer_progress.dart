class TransferProgress {
  final int downloaded;
  final int total;
  final double speedMb;
  final Duration elapsed;
  final Duration? remaining;
  final DateTime timestamp;

  TransferProgress({
    required this.downloaded,
    required this.total,
    required this.speedMb,
    required this.elapsed,
    this.remaining,
  }) : timestamp = DateTime.now();

  double get percent => total > 0 ? (downloaded / total) * 100.0 : 0.0;

  String get speedStr =>
      speedMb >= 0 ? '${speedMb.toStringAsFixed(1)} MB/s' : '-- MB/s';

  String get elapsedStr {
    final elapsedMinutes = elapsed.inMinutes;
    final elapsedSeconds = elapsed.inSeconds % 60;
    return '${elapsedMinutes}m ${elapsedSeconds}s';
  }

  DateTime? get eta => remaining != null ? timestamp.add(remaining!) : null;

  String get etaStr {
    if (remaining == null || remaining!.inSeconds <= 0) {
      return '--';
    }
    final remainingSec = remaining!.inSeconds;
    if (remainingSec < 60) {
      return '${remainingSec}s';
    } else if (remainingSec < 3600) {
      return '${remainingSec ~/ 60}m ${remainingSec % 60}s';
    } else {
      final hours = remainingSec ~/ 3600;
      final minutes = (remainingSec % 3600) ~/ 60;
      final seconds = remainingSec % 60;
      return '${hours}h ${minutes}m ${seconds}s';
    }
  }

  @override
  String toString() {
    final percentStr = percent.toStringAsFixed(2);
    return '$percentStr% ($speedStr) [Elapsed: $elapsedStr, ETA: $etaStr]';
  }
}
