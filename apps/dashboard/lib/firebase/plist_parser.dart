import 'dart:convert';
import 'package:xml/xml.dart';

import 'firebase_config_provider.dart';

bool isBinaryPlist(List<int> bytes) {
  if (bytes.length < 8) return false;
  return bytes[0] == 0x62 &&
      bytes[1] == 0x70 &&
      bytes[2] == 0x6C &&
      bytes[3] == 0x69 &&
      bytes[4] == 0x73 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x30 &&
      bytes[7] == 0x30;
}

bool isUtf16Le(List<int> bytes) {
  return bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE;
}

bool isUtf16Be(List<int> bytes) {
  return bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF;
}

String decodeUtf16(List<int> bytes, {required bool isLittleEndian}) {
  final chars = <int>[];
  for (var i = 2; i < bytes.length - 1; i += 2) {
    final code = isLittleEndian
        ? (bytes[i + 1] << 8) | bytes[i]
        : (bytes[i] << 8) | bytes[i + 1];
    chars.add(code);
  }
  return String.fromCharCodes(chars);
}

/// Tries to parse file content as JSON (google-services.json) and returns
/// a [SelfHostedConfig] if successful.
///
/// Throws a [FormatException] if parsing fails or required keys are missing.
SelfHostedConfig parseJsonConfig(String content) {
  Map<String, dynamic> map;
  try {
    map = jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    throw FormatException('JSONのパースに失敗しました: $e');
  }

  // Web-style firebase config JSON (has apiKey at top-level)
  if (map.containsKey('apiKey')) {
    final apiKey = map['apiKey'] as String?;
    final appId = map['appId'] as String?;
    final projectId = map['projectId'] as String?;

    final missingKeys = <String>[];
    if (apiKey == null || apiKey.isEmpty) missingKeys.add('apiKey');
    if (appId == null || appId.isEmpty) missingKeys.add('appId');
    if (projectId == null || projectId.isEmpty) missingKeys.add('projectId');

    if (missingKeys.isNotEmpty) {
      throw FormatException('必須キーが不足しています: ${missingKeys.join(', ')}');
    }

    return SelfHostedConfig.fromJson(map);
  }

  // Android google-services.json style
  final projectInfo = map['project_info'] as Map<String, dynamic>?;
  final clients = map['client'] as List<dynamic>?;
  if (projectInfo != null && clients != null && clients.isNotEmpty) {
    final client = clients[0] as Map<String, dynamic>;
    final clientInfo = client['client_info'] as Map<String, dynamic>? ?? {};
    final apiKeys = client['api_key'] as List<dynamic>? ?? [];
    final appId = clientInfo['mobilesdk_app_id'] as String? ?? '';
    final apiKey = apiKeys.isNotEmpty
        ? (apiKeys[0] as Map<String, dynamic>)['current_key'] as String? ?? ''
        : '';
    final projectId = projectInfo['project_id'] as String? ?? '';
    final storageBucket = projectInfo['storage_bucket'] as String? ?? '';
    final projectNumber = projectInfo['project_number'] as String? ?? '';

    final missingKeys = <String>[];
    if (apiKey.isEmpty) missingKeys.add('current_key (API Key)');
    if (appId.isEmpty) missingKeys.add('mobilesdk_app_id (App ID)');
    if (projectId.isEmpty) missingKeys.add('project_id (Project ID)');

    if (missingKeys.isNotEmpty) {
      throw FormatException(
        'google-services.jsonの必須キーが不足しています: ${missingKeys.join(', ')}',
      );
    }

    return SelfHostedConfig(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: projectNumber,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }

  throw const FormatException(
    '未対応の形式です。Web用のFirebase設定(JSON)、Android用のgoogle-services.json、あるいはiOS用のGoogleService-Info.plistを選択してください。',
  );
}

/// Parses a GoogleService-Info.plist (XML) and extracts Firebase config values
/// into a [SelfHostedConfig].
///
/// Throws a [FormatException] if the plist cannot be parsed or required keys are missing.
SelfHostedConfig parsePlist(String plistContent) {
  var sanitized = plistContent.trim();
  if (sanitized.startsWith('\uFEFF')) {
    sanitized = sanitized.substring(1);
  }

  XmlDocument document;
  try {
    document = XmlDocument.parse(sanitized);
  } catch (e) {
    throw FormatException('XMLのパースに失敗しました: $e');
  }

  final dicts = document.findAllElements('dict');
  if (dicts.isEmpty) {
    throw const FormatException('plist内に <dict> 要素が見つかりません。');
  }
  final dict = dicts.first;

  final map = _parseDictElement(dict);

  final apiKey = map['API_KEY'] as String?;
  final appId = map['GOOGLE_APP_ID'] as String?;
  final projectId = map['PROJECT_ID'] as String?;

  final missingKeys = <String>[];
  if (apiKey == null || apiKey.isEmpty) missingKeys.add('API_KEY');
  if (appId == null || appId.isEmpty) missingKeys.add('GOOGLE_APP_ID');
  if (projectId == null || projectId.isEmpty) missingKeys.add('PROJECT_ID');

  if (missingKeys.isNotEmpty) {
    throw FormatException(
      'GoogleService-Info.plistの必須キーが不足しています: ${missingKeys.join(', ')}',
    );
  }

  return SelfHostedConfig(
    apiKey: apiKey!,
    appId: appId!,
    messagingSenderId: (map['GCM_SENDER_ID'] as String?) ?? '',
    projectId: projectId!,
    storageBucket: (map['STORAGE_BUCKET'] as String?) ?? '',
  );
}

/// Parses a `<dict>` element into a `Map<String, Object>`.
///
/// Supports `<string>`, `<integer>`, `<real>`, `<true/>`, `<false/>`,
/// `<array>`, and nested `<dict>` values.
Map<String, Object> _parseDictElement(XmlElement dict) {
  final result = <String, Object>{};
  final children = dict.children.whereType<XmlElement>().toList();

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
