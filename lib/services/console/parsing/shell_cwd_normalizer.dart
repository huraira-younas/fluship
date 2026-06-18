/// Strips shell prompt noise from captured working-directory text.
String? normalizeShellCwd(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return null;

  final lines = value
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('__FLUSHIP'))
      .where((line) => line.toLowerCase() != 'cd')
      .toList();

  if (lines.isNotEmpty) value = lines.last;

  final promptIndex = value.indexOf('>');
  if (promptIndex != -1) {
    if (promptIndex < value.length - 1) {
      final afterPrompt = value.substring(promptIndex + 1).trim();
      if (afterPrompt.isNotEmpty) value = afterPrompt;
    } else {
      value = value.substring(0, promptIndex);
    }
  }

  value = value.trim();
  return value.isEmpty ? null : value;
}
