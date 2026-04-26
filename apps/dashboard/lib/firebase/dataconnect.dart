import 'package:dashboard/generated/dataconnect/default.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';

export 'package:dashboard/generated/dataconnect/default.dart';

DefaultConnector get dataConnector => DefaultConnector.instance;

DateTime dateTimeFromDataConnect(Timestamp timestamp) => timestamp.toDateTime();

AnyValue anyValue(Object? value) => AnyValue(value);

Map<String, Object?> anyMap(AnyValue? value) {
  final raw = value?.value;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> anyList(AnyValue? value) {
  final raw = value?.value;
  return raw is List ? raw : const [];
}
