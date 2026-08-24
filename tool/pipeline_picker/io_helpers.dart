import 'dart:convert';
import 'dart:io';

String pathJoin(
  String a,
  String b, [
  String? c,
  String? d,
  String? e,
  String? f,
]) {
  var result = _join2(a, b);
  if (c != null) result = _join2(result, c);
  if (d != null) result = _join2(result, d);
  if (e != null) result = _join2(result, e);
  if (f != null) result = _join2(result, f);
  return result;
}

String _join2(String a, String b) {
  if (a.isEmpty) return b;
  final sep = Platform.pathSeparator;
  if (a.endsWith('/') || a.endsWith(r'\')) return '$a$b';
  return '$a$sep$b';
}

String absolutePath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';
  return File(trimmed).absolute.path;
}

bool fileExists(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return false;
  return File(trimmed).existsSync();
}

bool dirExists(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return false;
  return Directory(trimmed).existsSync();
}

Map<String, dynamic> readJsonFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } catch (_) {}
  return <String, dynamic>{};
}

void writeJsonFile(String path, Map<String, dynamic> data) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
}

String readText(String path) {
  return File(path).readAsStringSync();
}

bool looksLikeJsonObject(String value) {
  final trimmed = value.trim();
  return trimmed.startsWith('{') && trimmed.endsWith('}');
}

bool secretPresent(String? value) {
  return value != null && value.trim().isNotEmpty;
}

bool secretFileOrJsonPresent(String? value) {
  if (!secretPresent(value)) return false;
  final trimmed = value!.trim();
  if (looksLikeJsonObject(trimmed)) return true;
  return fileExists(trimmed);
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

List<String> asStringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item != null && '$item'.trim().isNotEmpty) '$item'.trim(),
  ];
}

String asString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}
