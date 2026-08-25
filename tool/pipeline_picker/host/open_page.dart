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
/// Returns true when a browser open was attempted and succeeded.
Future<bool> openPickerPage(
  String url, {
  PickerOpenPlan? plan,
  bool open = true,
}) async {
  final resolved = plan ?? planPickerOpen(url);
  if (!open) return false;
  if (resolved.target == openInCursorIde) {
    return openInCursorIdeBrowser(url);
  }
  await openInChromeBrowser(url);
  return true;
}

Future<bool> openInCursorIdeBrowser(String url) async {
  if (Platform.isMacOS) {
    await Process.run('osascript', [
      '-e',
      'tell application "Cursor" to activate',
    ]);
  }
  final uris = <String>[
    cursorSimpleBrowserUri(url),
    'cursor://vscode.simple-browser/show?url=${Uri.encodeComponent(url)}',
  ];
  for (final uri in uris) {
    if (await _openCursorUri(uri)) return true;
  }
  if (await _openCursorCommand(url)) return true;
  return _openHttpInCursor(url);
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

/// Host and port of the picker page. Chrome tabs are matched on this, so a
/// stale page from an older run on another port is left alone.
String pickerTabNeedle(String url) {
  final parsed = Uri.tryParse(url.trim());
  if (parsed == null || parsed.host.isEmpty) return '';
  return parsed.hasPort ? '${parsed.host}:${parsed.port}' : parsed.host;
}

/// Closes only the Chrome tabs showing the picker, and answers 0 when Chrome
/// is not running so the script can never launch it.
String chromeCloseTabScript(String needle) {
  return '''
if application "Google Chrome" is running then
  tell application "Google Chrome"
    set closedCount to 0
    repeat with theWindow in windows
      set tabIndex to (count of tabs of theWindow)
      repeat while tabIndex > 0
        if URL of tab tabIndex of theWindow contains "$needle" then
          close tab tabIndex of theWindow
          set closedCount to closedCount + 1
        end if
        set tabIndex to tabIndex - 1
      end repeat
    end repeat
    return closedCount
  end tell
else
  return 0
end if
''';
}

/// Closes the picker tab once the run is picked or cancelled.
///
/// Only Chrome can be closed from here, and only on macOS. A Cursor tab has no
/// external close API, and the agent must not close it either, so the user
/// closes that one in their own time. Never ask the page to close itself:
/// `window.close()` inside the Cursor browser takes the whole Cursor window
/// down with it.
Future<int> closePickerTab(String url) async {
  if (!Platform.isMacOS) return 0;
  final needle = pickerTabNeedle(url);
  if (needle.isEmpty) return 0;
  try {
    final result = await Process.run('osascript', [
      '-e',
      chromeCloseTabScript(needle),
    ]);
    if (result.exitCode != 0) return 0;
    return int.tryParse(result.stdout.toString().trim()) ?? 0;
  } catch (_) {
    return 0;
  }
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

Future<bool> _openHttpInCursor(String url) async {
  try {
    if (Platform.isMacOS) {
      final result = await Process.run('open', ['-a', 'Cursor', url]);
      return result.exitCode == 0;
    }
    final result = await Process.run(_cursorBin(), ['--reuse-window', url]);
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
