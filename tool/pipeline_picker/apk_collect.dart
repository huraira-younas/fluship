import 'dart:io';

import 'io_helpers.dart';

List<String> collectShareApks({
  required String outputDir,
  String? projectPath,
}) {
  final files = <File>[];
  _addApks(files, outputDir);
  if (projectPath != null && projectPath.trim().isNotEmpty) {
    _addApks(
      files,
      pathJoin(projectPath, 'build', 'app', 'outputs', 'flutter-apk'),
    );
  }

  final byName = <String, File>{};
  for (final file in files) {
    byName[file.path] = file;
  }
  final unique = byName.values.toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final v7a = [
    for (final file in unique)
      if (_nameOf(file).contains('armeabi-v7a')) file.path,
  ];
  final v8a = [
    for (final file in unique)
      if (_nameOf(file).contains('arm64-v8a')) file.path,
  ];
  if (v7a.isNotEmpty || v8a.isNotEmpty) {
    return [...v7a.take(1), ...v8a.take(1)];
  }

  final fat = [
    for (final file in unique)
      if (_isFatReleaseApk(_nameOf(file))) file.path,
  ];
  return fat.take(1).toList();
}

void _addApks(List<File> files, String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final name = _nameOf(entity).toLowerCase();
    if (!name.endsWith('.apk')) continue;
    if (name.contains('x86')) continue;
    files.add(entity);
  }
}

String _nameOf(File file) =>
    file.uri.pathSegments.isEmpty ? file.path : file.uri.pathSegments.last;

bool _isFatReleaseApk(String name) {
  final lower = name.toLowerCase();
  if (!lower.endsWith('.apk')) return false;
  if (lower.contains('armeabi-v7a') ||
      lower.contains('arm64-v8a') ||
      lower.contains('x86')) {
    return false;
  }
  return lower.contains('release') || lower == 'app-release.apk';
}
