import 'package:xml/xml.dart';

import 'firebase_config_provider.dart';

/// Parses a GoogleService-Info.plist (XML) and extracts Firebase config values
/// into a [SelfHostedConfig].
///
/// Returns `null` if the plist cannot be parsed or required keys are missing.
SelfHostedConfig? parsePlist(String plistContent) {
  try {
    final document = XmlDocument.parse(plistContent);
    final dict = document.findAllElements('dict').first;

    final map = _parseDictElement(dict);

    final apiKey = map['API_KEY'] as String?;
    final appId = map['GOOGLE_APP_ID'] as String?;
    final projectId = map['PROJECT_ID'] as String?;

    if (apiKey == null || appId == null || projectId == null) {
      return null;
    }

    return SelfHostedConfig(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: (map['GCM_SENDER_ID'] as String?) ?? '',
      projectId: projectId,
      storageBucket: (map['STORAGE_BUCKET'] as String?) ?? '',
    );
  } catch (_) {
    return null;
  }
}

/// Parses a `<dict>` element into a `Map<String, Object>`.
///
/// Supports `<string>`, `<integer>`, `<real>`, `<true/>`, `<false/>`,
/// `<array>`, and nested `<dict>` values.
Map<String, Object> _parseDictElement(XmlElement dict) {
  final result = <String, Object>{};
  final children =
      dict.children.whereType<XmlElement>().toList();

  for (var i = 0; i < children.length - 1; i++) {
    final child = children[i];
    if (child.name.local == 'key') {
      final key = child.innerText;
      final value = children[i + 1];
      final parsed = _parseValue(value);
      if (parsed != null) {
        result[key] = parsed;
      }
      i++; // skip the value element
    }
  }

  return result;
}

Object? _parseValue(XmlElement element) {
  switch (element.name.local) {
    case 'string':
      return element.innerText;
    case 'integer':
      return int.tryParse(element.innerText);
    case 'real':
      return double.tryParse(element.innerText);
    case 'true':
      return true;
    case 'false':
      return false;
    case 'dict':
      return _parseDictElement(element);
    case 'array':
      return element.children
          .whereType<XmlElement>()
          .map(_parseValue)
          .whereType<Object>()
          .toList();
    default:
      return null;
  }
}
