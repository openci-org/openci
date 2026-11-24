/// Select a worker by passing an enum literal such as [MachineType.linuxLatest]
/// to the workflow's `machine` argument.
enum MachineType {
  macOsLatest('macos-latest'),
  linuxLatest('linux-latest');

  const MachineType(this.runsOn);
  final String runsOn;
}
