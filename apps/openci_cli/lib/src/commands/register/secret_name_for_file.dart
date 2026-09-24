import 'package:path/path.dart' as p;

String secretNameForFile(String filePath, {p.Context? pathContext}) {
  final fileName = (pathContext ?? p.context).basename(filePath);
  var name = fileName.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]+'), '_');
  if (RegExp(r'^[0-9]').hasMatch(name)) name = '_$name';
  return '${name}_BASE64';
}
