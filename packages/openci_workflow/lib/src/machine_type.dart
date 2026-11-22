enum MachineType {
  macOsLatest('macos-latest'),
  linuxLatest('linux-latest');

  const MachineType(this.runsOn);
  final String runsOn;
}
