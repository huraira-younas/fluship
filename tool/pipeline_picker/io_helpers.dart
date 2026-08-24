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

String fileNameOf(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.replaceAll('\\', '/').split('/');
  return parts.isEmpty ? trimmed : parts.last;
}

String readFileTail(String path, {int maxBytes = 8192}) {
  final file = File(path);
  if (!file.existsSync()) return '';
  final length = file.lengthSync();
  if (length <= 0) return '';
  final start = length > maxBytes ? length - maxBytes : 0;
  final raf = file.openSync();
  try {
    raf.setPositionSync(start);
    return String.fromCharCodes(raf.readSync(length - start));
  } finally {
    raf.closeSync();
  }
}

void deleteIfExists(String path) {
  final file = File(path);
  if (!file.existsSync()) return;
  try {
    file.deleteSync();
  } catch (_) {}
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

/// Parses `--key value`, `--key=value`, and bare `--flag` (which becomes
/// `'true'`). A value that starts with `--` is treated as the next flag, so a
/// missing value can never swallow one. Repeated `--file` values are joined
/// with newlines under `files`.
Map<String, String> parseCliFlags(List<String> args) {
  final result = <String, String>{};
  final files = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--help' || arg == '-h') {
      result['help'] = 'true';
      continue;
    }
    if (!arg.startsWith('--')) continue;
    final key = arg.substring(2);
    final eq = key.indexOf('=');
    if (eq >= 0) {
      result[key.substring(0, eq)] = key.substring(eq + 1);
      continue;
    }
    if (i + 1 >= args.length || args[i + 1].startsWith('--')) {
      result[key] = 'true';
      continue;
    }
    final value = args[++i];
    if (key == 'file' || key == 'files') {
      files.add(value);
    } else {
      result[key] = value;
    }
  }
  if (files.isNotEmpty) result['files'] = files.join('\n');
  return result;
}

String flagString(
  Map<String, String> flags,
  String key, [
  String fallback = '',
]) {
  final value = flags[key]?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

bool flagBool(Map<String, String> flags, String key, {bool fallback = false}) {
  final value = flags[key]?.trim().toLowerCase();
  if (value == null || value.isEmpty) return fallback;
  return value != 'false' && value != '0' && value != 'no';
}

int flagInt(
  Map<String, String> flags,
  String key,
  int fallback, {
  int min = 0,
}) {
  final parsed = int.tryParse(flags[key]?.trim() ?? '') ?? fallback;
  return parsed < min ? min : parsed;
}

List<String> csvValues(String raw) {
  return [
    for (final part in raw.split(RegExp(r'[\n,]')))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}

/// The repo root, found from the running script instead of the process cwd.
String workspaceRoot() {
  final cached = _workspaceRoot;
  if (cached != null) return cached;
  var dir = File.fromUri(Platform.script).absolute.parent;
  for (var i = 0; i < 8; i++) {
    if (dirExists(pathJoin(dir.path, 'tool')) &&
        fileExists(pathJoin(dir.path, 'pubspec.yaml'))) {
      return _workspaceRoot = dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return _workspaceRoot = Directory.current.path;
}

String? _workspaceRoot;

/// Anchors `.fluship-agent` files to the workspace. A wrong cwd would otherwise
/// read an empty cache or write a second, stray agent folder.
String resolveAgentPath(String? value, String fallbackName) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return pathJoin(workspaceRoot(), '.fluship-agent', fallbackName);
  }
  if (File(raw).isAbsolute) return raw;
  return pathJoin(workspaceRoot(), raw);
}

String? resolveToolScript(String name) {
  var dir = File.fromUri(Platform.script).absolute.parent;
  for (var i = 0; i < 8; i++) {
    final here = pathJoin(dir.path, name);
    if (File(here).existsSync()) return here;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  final fromCwd = pathJoin(Directory.current.path, 'tool', name);
  if (File(fromCwd).existsSync()) return fromCwd;
  return null;
}
