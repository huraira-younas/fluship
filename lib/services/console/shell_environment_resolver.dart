import 'dart:io' show File, Platform, Process;
import 'package:path/path.dart' as p;

class ShellEnvironmentResolver {
  const ShellEnvironmentResolver();

  static String? _cachedLoginPath;

  Future<Map<String, String>> resolve({
    required String workingDirectory,
  }) async {
    final env = Map<String, String>.from(Platform.environment);

    final loginPath = await _resolveLoginShellPath();
    if (loginPath != null && loginPath.isNotEmpty) {
      env['PATH'] = loginPath;
    }

    final flutterRoot = await _resolveFlutterRoot(workingDirectory);
    if (flutterRoot != null && flutterRoot.isNotEmpty) {
      env['FLUTTER_ROOT'] = flutterRoot;
      env['PATH'] = prependPathSegment(
        segment: p.join(flutterRoot, 'bin'),
        path: env['PATH'],
      );
    }

    return env;
  }

  static String prependPathSegment({
    required String segment,
    required String? path,
  }) {
    final normalized = p.normalize(segment);
    final current = path ?? '';
    if (current.isEmpty) return normalized;

    final separator = Platform.isWindows ? ';' : ':';
    final entries = current.split(separator);
    if (entries.contains(normalized)) return current;

    return '$normalized$separator$current';
  }

  static String? parseFlutterRootFromConfig(String content) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('FLUTTER_ROOT=')) {
        return trimmed.substring('FLUTTER_ROOT='.length).trim();
      }
      if (trimmed.startsWith('flutter.sdk=')) {
        return trimmed.substring('flutter.sdk='.length).trim();
      }
    }

    return null;
  }

  Future<String?> _resolveLoginShellPath() async {
    if (!Platform.isMacOS && !Platform.isLinux) return null;

    final cached = _cachedLoginPath;
    if (cached != null) return cached;

    final shell =
        Platform.environment['SHELL'] ??
        (Platform.isMacOS ? '/bin/zsh' : '/bin/bash');

    try {
      final result = await Process.run(shell, const [
        '-lic',
        r'echo -n $PATH',
      ], runInShell: false);
      if (result.exitCode != 0) return null;

      final path = (result.stdout as String).trim();
      if (path.isEmpty) return null;

      _cachedLoginPath = path;
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveFlutterRoot(String projectRoot) async {
    final candidates = [
      p.join(projectRoot, 'macos/Flutter/ephemeral/Flutter-Generated.xcconfig'),
      p.join(projectRoot, 'ios/Flutter/Generated.xcconfig'),
      p.join(projectRoot, 'android/local.properties'),
    ];

    for (final candidate in candidates) {
      final file = File(candidate);
      if (!await file.exists()) continue;

      final content = await file.readAsString();
      final root = parseFlutterRootFromConfig(content);
      if (root != null && root.isNotEmpty) return root;
    }

    return null;
  }
}
