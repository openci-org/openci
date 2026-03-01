import 'dart:io';

enum VMStatus { creating, running, stopping, stopped, error }

class VMInstance {
  final String id;
  final String bundlePath;
  final DateTime createdAt;
  String? ip;
  String? macAddress;
  VMStatus status;
  Process? process;

  VMInstance({
    required this.id,
    required this.bundlePath,
    this.ip,
    this.macAddress,
    this.status = VMStatus.creating,
  }) : createdAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'bundle_path': bundlePath,
    'status': status.name,
    'ip': ip,
    'mac_address': macAddress,
    'created_at': createdAt.toIso8601String(),
    'uptime_seconds': DateTime.now().difference(createdAt).inSeconds,
  };
}
