import '../models/console_line.dart';

final _mbPairRe = RegExp(r'\d+(?:\.\d+)?\s*/\s*\d+(?:\.\d+)?\s*mb');
final _nonzeroErrorsRe = RegExp(r'(?<![0-9])[1-9]\d*\s+error');
final _exceptionRe = RegExp(r'\bexception\b');
final _exitRe = RegExp(r'\[exit\s+(-?\d+)\]');
final _leadingErrorRe = RegExp(r'^error\b');
final _percentRe = RegExp(r'\b\d{1,3}%\b');
final _errorColonRe = RegExp(r'\berror:');
final _failedRe = RegExp(r'\bfailed\b');
final _fatalRe = RegExp(r'\bfatal\b');

ConsoleLineKind classifyConsoleLine(String text, [ConsoleStream? stream]) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return .info;
  if (stream == .input || trimmed.startsWith('> ')) return .info;

  final lower = trimmed.toLowerCase();

  final exit = _exitRe.firstMatch(trimmed);
  if (exit != null) {
    final code = int.tryParse(exit.group(1)!);
    return code != null && code != 0 ? .error : .info;
  }

  if (trimmed == '[cancelled]' ||
      (lower.contains('cancelled') &&
          (lower.contains('pipeline') || lower.contains(' after ')))) {
    return .warn;
  }

  if (_isError(lower)) return .error;
  if (_isWarn(lower)) return .warn;
  if (_isProgress(trimmed, lower)) return .progress;
  if (_isSuccess(lower)) return .success;
  return .info;
}

ConsoleLineKind upgradeConsoleLineKind(
  ConsoleLineKind? current,
  ConsoleLineKind incoming,
) {
  if (current == null) return incoming;
  return _rank(incoming) >= _rank(current) ? incoming : current;
}

int _rank(ConsoleLineKind kind) => switch (kind) {
  .error => 4,
  .warn => 3,
  .success || .progress => 2,
  .info => 1,
};

bool _isError(String lower) {
  if (lower.contains('0 error')) return false;
  if (_failedRe.hasMatch(lower)) return true;
  if (_fatalRe.hasMatch(lower)) return true;
  if (_exceptionRe.hasMatch(lower)) return true;
  if (_errorColonRe.hasMatch(lower)) return true;
  if (_leadingErrorRe.hasMatch(lower)) return true;
  if (lower.contains('compilation failed')) return true;
  if (lower.contains('build failed')) return true;
  if (_nonzeroErrorsRe.hasMatch(lower)) return true;
  return false;
}

bool _isWarn(String lower) {
  if (lower.contains('warning:')) return true;
  if (lower.contains('deprecated')) return true;
  if (lower.startsWith('note:')) return true;
  return false;
}

bool _isProgress(String text, String lower) {
  if (_mbPairRe.hasMatch(lower)) return true;
  if (!_percentRe.hasMatch(text)) return false;
  return lower.contains('upload') ||
      lower.contains('play store') ||
      lower.contains('app store') ||
      lower.contains('drive');
}

bool _isSuccess(String lower) {
  if (lower.contains('finished in')) return true;
  if (lower.contains('uploaded')) return true;
  if (lower.contains('emailed')) return true;
  if (lower.contains('completed successfully')) return true;
  if (lower.contains('completed in') && !lower.contains('failed')) return true;
  return false;
}

extension ConsoleLineDisplay on ConsoleLine {
  ConsoleLineKind get displayKind => kind ?? classifyConsoleLine(text, stream);
}
