/// Dart bindings for Apple's Virtualization.Framework.
///
/// Create, install, clone, and run macOS virtual machines programmatically.
///
/// ```dart
/// import 'package:dart_avf/dart_avf.dart';
///
/// final ipsw = await MacOSRestoreImage.fetchLatest();
/// final vm = await MacVM.create(
///   bundlePath: 'my-vm.bundle',
///   ipswPath: ipsw.path,
/// );
/// await vm.install();
/// await vm.start();
/// ```
library;

export 'src/ipsw.dart';
export 'src/mac_vm.dart';
export 'src/virtualization_bindings.dart';
export 'src/vm_config.dart';
