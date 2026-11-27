/// Select a worker by passing a preset to the workflow's `machine` argument.
enum MachineType {
  macOsLatest('macos-latest'),

  /// A Linux VM with 1 vCPU and 2 GiB of RAM.
  linuxSmall('linux-small'),

  /// A Linux VM with 2 vCPUs and 4 GiB of RAM.
  linuxMedium('linux-medium'),

  /// A Linux VM with 4 vCPUs and 8 GiB of RAM.
  linuxLarge('linux-large');

  const MachineType(this.runsOn);
  final String runsOn;
}
