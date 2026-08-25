import 'dart:io';

/// Opens a system URL such as WhatsApp. Do not use this for the picker page.
/// The picker uses open_page.dart so Cursor stays in the IDE panel.
Future<void> revealOutput(String path) async {
  final file = File(path);
  final folder = file.parent.path;
  if (Platform.isMacOS) {
    if (file.existsSync()) {
      await Process.run('open', ['-R', path]);
    } else {
      await Process.run('open', [folder]);
    }
    return;
  }
  if (Platform.isWindows) {
    if (file.existsSync()) {
      await Process.run('explorer', ['/select,', path]);
    } else {
      await Process.run('explorer', [folder]);
    }
    return;
  }
  await Process.run('xdg-open', [folder]);
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

/// Native file picker for the Setup panel. macOS skips the type filter because
/// AppleScript reads those strings as UTIs and a key file such as .p8 has none.
Future<String?> browseFile({
  required String prompt,
  List<String> fileTypes = const <String>[],
}) async {
  final title = prompt.isEmpty ? 'Select a file' : prompt;
  try {
    if (Platform.isMacOS) {
      final result = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose file with prompt "${_escapeForOsa(title)}")',
      ]);
      if (result.exitCode != 0) return null;
      final path = result.stdout.toString().trim();
      return path.isEmpty ? null : path;
    }
    if (Platform.isWindows) {
      final script =
          '''
Add-Type -AssemblyName System.Windows.Forms
\$d = New-Object System.Windows.Forms.OpenFileDialog
\$d.Title = "${_escapeForPowerShell(title)}"
\$d.Filter = "${_windowsFilter(fileTypes)}"
if (\$d.ShowDialog() -eq 'OK') { \$d.FileName }
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

String _windowsFilter(List<String> fileTypes) {
  const all = 'All files (*.*)|*.*';
  if (fileTypes.isEmpty) return all;
  final patterns = [for (final type in fileTypes) '*.$type'].join(';');
  return '${fileTypes.join(', ').toUpperCase()} files ($patterns)|$patterns|$all';
}

String _escapeForOsa(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}

String _escapeForPowerShell(String value) {
  return value.replaceAll('"', "'");
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
