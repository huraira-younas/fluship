import 'dart:io';

/// Opens a system URL such as WhatsApp. Do not use this for the picker page.
/// The picker uses open_page.dart so Cursor stays in the IDE panel.
Future<void> openBrowser(String url) async {
  if (Platform.isMacOS) {
    await Process.start('open', [url], mode: ProcessStartMode.detached);
    return;
  }
  if (Platform.isWindows) {
    await Process.start('cmd', [
      '/c',
      'start',
      '',
      url,
    ], mode: ProcessStartMode.detached);
    return;
  }
  await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
}

Future<String?> browseFolder() async {
  try {
    if (Platform.isMacOS) {
      final result = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose folder with prompt "Select Flutter project")',
      ]);
      if (result.exitCode != 0) return null;
      final path = result.stdout.toString().trim();
      return path.isEmpty ? null : path;
    }
    if (Platform.isWindows) {
      const script = '''
Add-Type -AssemblyName System.Windows.Forms
\$d = New-Object System.Windows.Forms.FolderBrowserDialog
\$d.Description = "Select Flutter project"
if (\$d.ShowDialog() -eq 'OK') { \$d.SelectedPath }
''';
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        script,
      ]);
      if (result.exitCode != 0) return null;
      final path = result.stdout.toString().trim();
      return path.isEmpty ? null : path;
    }
  } catch (_) {}
  return null;
}

bool pidAlive(int pid) {
  if (pid <= 0) return false;
  try {
    if (Platform.isWindows) {
      final result = Process.runSync('tasklist', ['/FI', 'PID eq $pid', '/NH']);
      return result.exitCode == 0 && result.stdout.toString().contains('$pid');
    }
    final result = Process.runSync('kill', ['-0', '$pid']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

String hostOsName() {
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return Platform.operatingSystem;
}
