/// VM configuration options.
class VMConfig {
  /// Number of CPU cores to allocate.
  final int cpuCount;

  /// Memory in GB.
  final int memoryGB;

  /// Disk size in GB (only used during creation).
  final int diskSizeGB;

  /// Display width in pixels.
  final int displayWidth;

  /// Display height in pixels.
  final int displayHeight;

  const VMConfig({
    this.cpuCount = 4,
    this.memoryGB = 8,
    this.diskSizeGB = 64,
    this.displayWidth = 1920,
    this.displayHeight = 1200,
  });
}
