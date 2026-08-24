import 'dart:io';

import 'open_page.dart';

/// Ask for Mac / host prompts at the start so the user does not leave
/// while a later flutter or WhatsApp step is waiting on Allow.
class WarmupReport {
  const WarmupReport({
    required this.cursorIde,
    required this.systemEvents,
    required this.finder,
    required this.whatsApp,
  });

  final bool cursorIde;
  final bool systemEvents;
  final bool finder;

  /// `null` means WhatsApp is not installed.
  final bool? whatsApp;

  bool get ready => !Platform.isMacOS || systemEvents;

  int get exitCode => ready ? 0 : 4;

  String get status => ready ? 'ready' : 'need-accessibility';
}

WarmupReport runWarmupProbes({
  Map<String, String>? env,
  bool? cursorAppRunning,
  bool? systemEvents,
  bool? finder,
  bool? whatsAppInstalled,
  bool? whatsAppControl,
}) {
  final isMac = Platform.isMacOS;
  return WarmupReport(
    cursorIde: shouldUseCursorIde(env: env, cursorAppRunning: cursorAppRunning),
    systemEvents: systemEvents ?? (isMac ? probeSystemEvents() : true),
    finder: finder ?? (isMac ? probeFinder() : true),
    whatsApp: _resolveWhatsApp(
      installed: whatsAppInstalled ?? isWhatsAppInstalled(),
      control: whatsAppControl,
    ),
  );
}

String formatWarmupBoard(WarmupReport report) {
  final wa = report.whatsApp;
  return [
    'Fluship warmup',
    'Stay in Cursor. Click Allow on every prompt now. Do not leave yet.',
    '',
    _line(report.systemEvents, 'System Events / Accessibility'),
    _line(report.finder, 'Finder control'),
    if (wa == null)
      '[SKIP] WhatsApp is not installed'
    else
      _line(wa, 'WhatsApp control'),
    if (report.cursorIde)
      '[OK] Picker will open in the Cursor browser panel. Chrome stays closed.'
    else
      '[OK] Cursor is not open. Picker will open in Chrome.',
    '',
    'warmup-status: ${report.status}',
    '',
    'Next for the agent:',
    '1. dart tool/pipeline_picker.dart',
    '2. Read Pipeline picker: URL and open-in: from stdout.',
    '3. If open-in is cursor-ide, the picker already opened one IDE tab. Do not open it again.',
    '4. Do not open Chrome while Cursor is open. Do not open a second picker tab.',
    '5. Every later shell command in this run must use full host permissions.',
  ].join('\n');
}

void openAccessibilitySettings() {
  if (!Platform.isMacOS) return;
  Process.runSync('open', [
    'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility',
  ]);
}

bool probeSystemEvents() {
  return _osascriptOk(
    'tell application "System Events" to get name of first process',
  );
}

bool probeFinder() {
  return _osascriptOk('tell application "Finder" to get name');
}

bool probeWhatsApp() {
  return _osascriptOk('tell application "WhatsApp" to get name');
}

bool isWhatsAppInstalled() {
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '';
    return Directory('/Applications/WhatsApp.app').existsSync() ||
        (home.isNotEmpty &&
            Directory('$home/Applications/WhatsApp.app').existsSync());
  }
  if (Platform.isWindows) {
    final local = Platform.environment['LOCALAPPDATA'] ?? '';
    if (local.isEmpty) return false;
    return Directory('$local\\WhatsApp').existsSync() ||
        Directory('$local\\Programs\\WhatsApp').existsSync();
  }
  for (final name in ['whatsapp-desktop', 'whatsapp-for-linux', 'whatsapp']) {
    try {
      final result = Process.runSync('which', [name]);
      if (result.exitCode == 0) return true;
    } catch (_) {}
  }
  return File('/snap/bin/whatsapp-desktop-linux').existsSync();
}

bool _osascriptOk(String source) {
  try {
    final result = Process.runSync('osascript', ['-e', source]);
    return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
  } catch (_) {
    return false;
  }
}

bool? _resolveWhatsApp({required bool installed, bool? control}) {
  if (!installed) return null;
  return control ?? (Platform.isMacOS ? probeWhatsApp() : true);
}

String _line(bool ok, String label) {
  return ok ? '[OK] $label' : '[NEED] $label: click Allow now';
}
