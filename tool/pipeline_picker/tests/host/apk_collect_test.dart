import 'dart:io';

import '../../io_helpers.dart';
import '../../share/apk_collect.dart';

void main() {
  final root = Directory.systemTemp.createTempSync('fluship-apk-');
  try {
    File(pathJoin(root.path, 'app-release.apk')).writeAsStringSync('fat');
    File(
      pathJoin(root.path, 'app-x86_64-release.apk'),
    ).writeAsStringSync('x86');
    final fat = collectShareApks(outputDir: root.path);
    _check(fat.length == 1, 'one fat apk');
    _check(fat.single.endsWith('app-release.apk'), 'fat name');

    File(
      pathJoin(root.path, 'app-armeabi-v7a-release.apk'),
    ).writeAsStringSync('v7');
    File(
      pathJoin(root.path, 'app-arm64-v8a-release.apk'),
    ).writeAsStringSync('v8');
    final splits = collectShareApks(outputDir: root.path);
    _check(splits.length == 2, 'v7a and v8a');
    _check(splits.any((p) => p.contains('armeabi-v7a')), 'has v7a');
    _check(splits.any((p) => p.contains('arm64-v8a')), 'has v8a');
    _check(!splits.any((p) => p.contains('x86')), 'ignore x86');
  } finally {
    root.deleteSync(recursive: true);
  }
  stdout.writeln('apk collect tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
