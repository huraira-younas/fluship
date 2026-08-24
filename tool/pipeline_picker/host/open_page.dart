import 'dart:io';

/// Where the pipeline picker page should appear.
///
/// `cursor-ide` = Cursor Simple Browser / IDE browser panel.
/// `chrome` = Google Chrome, only when Cursor is not running.
const openInCursorIde = 'cursor-ide';
const openInChrome = 'chrome';

class PickerOpenPlan {
  const PickerOpenPlan({required this.target, required this.url});

  final String target;
  final String url;

  String get simpleBrowserUri => cursorSimpleBrowserUri(url);
}

/// Cursor agent sessions set these. A running Cursor app is also enough.
bool shouldUseCursorIde({Map<String, String>? env, bool? cursorAppRunning}) {
  final e = env ?? Platform.environment;
  if (e['CURSOR_AGENT'] == '1') return true;
  if ((e['VSCODE_PID'] ?? '').trim().isNotEmpty) return true;
  if ((e['CURSOR_LAYOUT'] ?? '').trim().isNotEmpty) return true;
  return cursorAppRunning ?? isCursorAppRunning();
}

PickerOpenPlan planPickerOpen(
  String url, {
  Map<String, String>? env,
  bool? cursorAppRunning,
}) {
  final target =
      shouldUseCursorIde(env: env, cursorAppRunning: cursorAppRunning)
      ? openInCursorIde
      : openInChrome;
  return PickerOpenPlan(target: target, url: url);
}

String cursorSimpleBrowserUri(String url) {
  return 'vscode://vscode.simple-browser/show?url=${Uri.encodeComponent(url)}';
}

/// Opens the picker. Never opens Chrome while Cursor should host the page.
Future<String> openPickerPage(
  String url, {
  PickerOpenPlan? plan,
  bool open = true,
}) async {
  final resolved = plan ?? planPickerOpen(url);
  if (!open) return resolved.target;
  if (resolved.target == openInCursorIde) {
    await openInCursorIdeBrowser(url);
    return openInCursorIde;
  }
  await openInChromeBrowser(url);
  return openInChrome;
}

Future<bool> openInCursorIdeBrowser(String url) async {
  final uris = <String>[
    cursorSimpleBrowserUri(url),
    'cursor://vscode.simple-browser/show?url=${Uri.encodeComponent(url)}',
  ];
  for (final uri in uris) {
    if (await _openCursorUri(uri)) return true;
  }
  return _openCursorCommand(url);
}

Future<void> openInChromeBrowser(String url) async {
  if (Platform.isMacOS) {
    final chrome = await Process.run('open', ['-a', 'Google Chrome', url]);
    if (chrome.exitCode == 0) return;
    await Process.start('open', [url], mode: ProcessStartMode.detached);
    return;
  }
  if (Platform.isWindows) {
    await Process.start('cmd', [
      '/c',
      'start',
      '',
      'chrome',
      url,
    ], mode: ProcessStartMode.detached);
    return;
  }
  for (final bin in const [
    'google-chrome',
    'google-chrome-stable',
    'chromium',
  ]) {
    try {
      await Process.start(bin, [url], mode: ProcessStartMode.detached);
      return;
    } catch (_) {}
  }
  await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
}

bool isCursorAppRunning() {
  try {
    if (Platform.isWindows) {
      final result = Process.runSync('tasklist', [
        '/FI',
        'IMAGENAME eq Cursor.exe',
        '/NH',
      ]);
      return result.stdout.toString().toLowerCase().contains('cursor.exe');
    }
    final result = Process.runSync('ps', ['-axc', '-o', 'comm=']);
    if (result.exitCode != 0) return false;
    for (final line in result.stdout.toString().split('\n')) {
      final name = line.trim();
      if (name == 'Cursor' || name == 'cursor') return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

Future<bool> _openCursorUri(String uri) async {
  try {
    if (Platform.isMacOS) {
      final result = await Process.run('open', ['-a', 'Cursor', uri]);
      return result.exitCode == 0;
    }
    final result = await Process.run(_cursorBin(), ['--reuse-window', uri]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<bool> _openCursorCommand(String url) async {
  try {
    final result = await Process.run(_cursorBin(), [
      '--reuse-window',
      '--command',
      'simpleBrowser.show',
      url,
    ]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

String _cursorBin() {
  final raw = Platform.environment['CURSOR_BIN'];
  if (raw == null) return 'cursor';
  final trimmed = raw.trim();
  return trimmed.isEmpty ? 'cursor' : trimmed;
}
