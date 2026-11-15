import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';

/// A snapshot of the exact compressed bytes referenced by a Hosting manifest.
class HostingFile {
  HostingFile(this.path, this.hash, this.compressed);

  final String path;
  final String hash;
  final File compressed;
}

/// Temporary compressed build output; service account keys are never stored.
class HostingFiles {
  HostingFiles._(this._temporary, this.files);

  final Directory _temporary;
  final List<HostingFile> files;

  static Future<HostingFiles> prepare(
    Directory content, {
    List<String> ignore = const [],
  }) async {
    final List<Glob> excluded;
    try {
      excluded = ignore.map((pattern) {
        // Do not silently interpret an unsupported negated ignore as a literal.
        if (pattern.startsWith('!')) throw const FormatException();
        return Glob(pattern, caseSensitive: true);
      }).toList();
    } on FormatException {
      throw const FormatException(
        'hosting.ignore must contain supported glob patterns '
        '(*, **, ?, character classes or braces; no negation or extglobs).',
      );
    }
    if (!await content.exists()) {
      throw ArgumentError('publicDirectory must be an existing directory.');
    }
    final root = Directory(await content.resolveSymbolicLinks());
    final temporary = await Directory.systemTemp.createTemp('openci-hosting-');
    final files = <HostingFile>[];
    try {
      Future<void> visit(Directory directory) async {
        await for (final entity in directory.list(followLinks: false)) {
          final name = entity.uri.pathSegments.where((p) => p.isNotEmpty).last;
          final relative = entity.path
              .substring(root.path.length + 1)
              .replaceAll(Platform.pathSeparator, '/');
          if ((name.startsWith('.') && name != '.well-known') ||
              name == 'node_modules' ||
              name == 'firebase.json' ||
              excluded.any((glob) => glob.matches(relative))) {
            continue;
          }
          if (entity is Link) {
            throw ArgumentError('publicDirectory must not contain symlinks.');
          }
          if (entity is Directory) {
            await visit(entity);
          } else if (entity is File) {
            final compressed = File('${temporary.path}/${files.length}.gz');
            await entity
                .openRead()
                .transform(gzip.encoder)
                .pipe(
                  compressed.openWrite(),
                );
            final hash = (await sha256.bind(compressed.openRead()).first)
                .toString();
            files.add(HostingFile('/$relative', hash, compressed));
          }
        }
      }

      await visit(root);
      if (files.isEmpty) {
        throw ArgumentError('publicDirectory must contain deployable files.');
      }
      files.sort((a, b) => a.path.compareTo(b.path));
      return HostingFiles._(temporary, files);
    } catch (_) {
      await temporary.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> close() async => _temporary.delete(recursive: true);
}
