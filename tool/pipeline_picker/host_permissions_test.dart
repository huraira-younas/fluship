import 'dart:io';

import 'host_permissions.dart';

void main() {
  final ready = runWarmupProbes(
    env: const {'CURSOR_AGENT': '1'},
    cursorAppRunning: false,
    systemEvents: true,
    finder: true,
    whatsAppInstalled: true,
    whatsAppControl: true,
  );
  _check(ready.ready, 'ready when system events ok');
  _check(ready.status == 'ready', 'status ready');
  _check(ready.exitCode == 0, 'exit 0');
  _check(ready.cursorIde, 'cursor ide from env');

  final board = formatWarmupBoard(ready);
  _check(board.contains('warmup-status: ready'), 'board status');
  _check(board.contains('Stay in Cursor'), 'stay here');
  _check(board.contains('Cursor browser panel'), 'panel copy');
  _check(board.contains('Chrome stays closed.'), 'no chrome');
  _check(board.contains('Do not open a second picker tab'), 'one tab');
  _check(!board.contains('\u2014'), 'board em-dash');

  final blocked = runWarmupProbes(
    env: const {},
    cursorAppRunning: false,
    systemEvents: false,
    finder: true,
    whatsAppInstalled: false,
  );
  if (Platform.isMacOS) {
    _check(!blocked.ready, 'blocked without system events');
    _check(blocked.exitCode == 4, 'exit 4');
    _check(blocked.status == 'need-accessibility', 'need status');
  }
  final blockedBoard = formatWarmupBoard(blocked);
  _check(blockedBoard.contains('[SKIP] WhatsApp is not installed'), 'skip wa');

  stdout.writeln('host permissions tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
