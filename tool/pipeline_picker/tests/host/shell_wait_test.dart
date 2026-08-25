import '../../host/shell_wait.dart';

void main() {
  _checkTerminalParsing();
  _checkLongPollIds();
  _checkFormatElapsed();
}

void _checkTerminalParsing() {
  const footer = '''
some build output
---
exit_code: 0
elapsed_ms: 2223
ended_at: 2026-08-25T12:00:00.000Z
---
''';
  _check(terminalHasExitCode(footer), 'footer has exit code');
  _check(terminalExitCode(footer) == 0, 'exit code zero');
  _check(!terminalHasExitCode('still running'), 'no footer yet');
  _check(terminalExitCode('still running') == null, 'no code yet');
}

void _checkLongPollIds() {
  _check(isLongPollStep('buildAab'), 'buildAab long');
  _check(isLongPollStep('buildIpa'), 'buildIpa long');
  _check(isLongPollStep('distPlayProduction'), 'distPlayProduction long');
  _check(isLongPollStep('distAppStore'), 'distAppStore long');
  _check(isLongPollStep('distDrive'), 'distDrive long');
  _check(!isLongPollStep('clean'), 'clean not long');
  _check(!isLongPollStep('analyze'), 'analyze not long');
  _check(!isLongPollStep('slackNotify'), 'slackNotify not long');
}

void _checkFormatElapsed() {
  _check(formatWaitElapsed(const Duration(seconds: 9)) == '9s', 'seconds');
  _check(formatWaitElapsed(const Duration(seconds: 125)) == '2m5s', 'minutes');
  _check(
    formatWaitElapsed(const Duration(seconds: 120)) == '2m',
    'even minutes',
  );
}

void _check(bool ok, String label) {
  if (!ok) throw StateError('FAIL: $label');
}
