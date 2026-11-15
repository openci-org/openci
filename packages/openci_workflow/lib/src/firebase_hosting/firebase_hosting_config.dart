import 'dart:convert';
import 'dart:io';

/// The static Hosting portion of a firebase.json file, ready for the REST API.
class FirebaseHostingConfig {
  FirebaseHostingConfig._(
    this.publicDirectory,
    this.servingConfig,
    this.ignore,
  );

  final String? publicDirectory;
  final Map<String, Object?> servingConfig;
  final List<String> ignore;

  static Future<FirebaseHostingConfig> load(
    File file, {
    required String siteId,
    String? target,
  }) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FileSystemException {
      throw ArgumentError('firebaseConfigPath must name a readable JSON file.');
    } on FormatException {
      // JSON errors can include private configuration values.
      throw const FormatException(
        'firebaseConfigPath must contain valid JSON.',
      );
    }
    final root = _object(decoded, 'firebase.json');
    final hosting = root['hosting'];
    final entries = hosting is List
        ? _objects(hosting, 'hosting')
        : [_object(hosting, 'hosting')];
    for (final entry in entries) {
      for (final key in ['site', 'target']) {
        if (entry.containsKey(key)) _string(entry[key], 'hosting.$key');
      }
      if (entry.containsKey('site') && entry.containsKey('target')) {
        throw const FormatException(
          'Hosting cannot specify both site and target.',
        );
      }
    }
    final matches = entries
        .where(
          (entry) => target != null
              ? entry['target'] == target
              : entry['site'] == siteId,
        )
        .toList();
    final Map<String, dynamic> selected;
    if (matches.length == 1) {
      selected = matches.single;
    } else if (matches.isEmpty &&
        target == null &&
        entries.length == 1 &&
        !entries.single.containsKey('site')) {
      // siteId is always explicit; a lone target needs no .firebaserc lookup.
      selected = entries.single;
    } else {
      throw ArgumentError(
        'firebase.json must select exactly one Hosting configuration for '
        'siteId or target. Pass target for configurations using deploy targets.',
      );
    }

    _keys(selected, {
      'site', 'target', 'public', 'ignore', 'headers', 'redirects', 'rewrites',
      'cleanUrls', 'trailingSlash', 'i18n', 'appAssociation',
      // Builds are run by the workflow; Firebase CLI hooks are not executed.
      'predeploy', 'postdeploy',
    }, 'hosting');
    final publicDirectory = selected.containsKey('public')
        ? _string(selected['public'], 'hosting.public')
        : null;
    final ignore = selected.containsKey('ignore')
        ? _list(
            selected['ignore'],
            'hosting.ignore',
          ).map((value) => _string(value, 'hosting.ignore')).toList()
        : <String>[];
    final config = <String, Object?>{};
    for (final key in ['cleanUrls', 'trailingSlash']) {
      if (!selected.containsKey(key)) continue;
      final value = selected[key];
      if (value is! bool) {
        throw FormatException('hosting.$key must be a boolean.');
      }
      if (key == 'trailingSlash') {
        config['trailingSlashBehavior'] = value ? 'ADD' : 'REMOVE';
      } else {
        config[key] = value;
      }
    }
    if (selected.containsKey('i18n')) {
      final i18n = _object(selected['i18n'], 'hosting.i18n');
      _keys(i18n, {'root'}, 'hosting.i18n');
      config['i18n'] = {'root': _string(i18n['root'], 'hosting.i18n.root')};
    }
    if (selected.containsKey('appAssociation')) {
      final value = selected['appAssociation'];
      if (value != 'AUTO' && value != 'NONE') {
        throw const FormatException(
          'hosting.appAssociation must be AUTO or NONE.',
        );
      }
      config['appAssociation'] = value;
    }
    if (selected.containsKey('headers')) {
      config['headers'] = _objects(selected['headers'], 'hosting.headers').map((
        rule,
      ) {
        _keys(rule, {'source', 'glob', 'regex', 'headers'}, 'hosting.headers');
        final headers = <String, String>{};
        for (final header in _objects(
          rule['headers'],
          'hosting.headers.headers',
        )) {
          _keys(header, {'key', 'value'}, 'hosting.headers.headers');
          final key = _string(header['key'], 'hosting.headers.headers.key');
          final value = header['value'];
          if (value is! String) {
            throw const FormatException(
              'Hosting header values must be strings.',
            );
          }
          headers[key] = value;
        }
        return {..._pattern(rule), 'headers': headers};
      }).toList();
    }
    if (selected.containsKey('redirects')) {
      config['redirects'] = _objects(selected['redirects'], 'hosting.redirects')
          .map((rule) {
            _keys(rule, {
              'source',
              'glob',
              'regex',
              'destination',
              'type',
            }, 'hosting.redirects');
            final status = rule['type'];
            if (status is! int || status < 300 || status > 399) {
              throw const FormatException(
                'Hosting redirect type must be a 3xx status code.',
              );
            }
            return {
              ..._pattern(rule),
              'location': _string(
                rule['destination'],
                'hosting.redirects.destination',
              ),
              'statusCode': status,
            };
          })
          .toList();
    }
    if (selected.containsKey('rewrites')) {
      config['rewrites'] = _objects(selected['rewrites'], 'hosting.rewrites')
          .map((rule) {
            if (['function', 'run', 'dynamicLinks'].any(rule.containsKey)) {
              throw const FormatException(
                'firebase.json supports only static destination rewrites. '
                'Use a REST ServingConfig for backend rewrites.',
              );
            }
            _keys(rule, {
              'source',
              'glob',
              'regex',
              'destination',
            }, 'hosting.rewrites');
            return {
              ..._pattern(rule),
              'path': _string(
                rule['destination'],
                'hosting.rewrites.destination',
              ),
            };
          })
          .toList();
    }
    return FirebaseHostingConfig._(publicDirectory, config, ignore);
  }
}

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$field must be a JSON object.');
  }
  return value;
}

List<dynamic> _list(Object? value, String field) {
  if (value is! List) throw FormatException('$field must be a JSON array.');
  return value;
}

List<Map<String, dynamic>> _objects(Object? value, String field) =>
    _list(value, field).map((entry) => _object(entry, field)).toList();

String _string(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value;
}

void _keys(Map<String, dynamic> value, Set<String> allowed, String field) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw FormatException(
      '$field contains unsupported static Hosting options.',
    );
  }
}

Map<String, String> _pattern(Map<String, dynamic> rule) {
  final keys = ['source', 'glob', 'regex'].where(rule.containsKey).toList();
  if (keys.length != 1) {
    throw const FormatException(
      'Hosting rules need exactly one source or regex.',
    );
  }
  final key = keys.single;
  return {
    key == 'source' ? 'glob' : key: _string(rule[key], 'Hosting rule pattern'),
  };
}
