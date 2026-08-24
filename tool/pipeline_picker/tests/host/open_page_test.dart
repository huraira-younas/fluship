import 'dart:io';

import '../../host/open_page.dart';

void main() {
  const url = 'http://127.0.0.1:4321/';
  _check(
    shouldUseCursorIde(
      env: const {'CURSOR_AGENT': '1'},
      cursorAppRunning: false,
    ),
    'agent env uses Cursor',
  );
  _check(
    shouldUseCursorIde(
      env: const {'VSCODE_PID': '99'},
      cursorAppRunning: false,
    ),
    'vscode pid uses Cursor',
  );
  _check(
    !shouldUseCursorIde(env: const {}, cursorAppRunning: false),
    'no cursor means chrome path',
  );
  _check(
    shouldUseCursorIde(env: const {}, cursorAppRunning: true),
    'running Cursor app uses panel',
  );

  _check(
    planPickerOpen(
          url,
          env: const {'CURSOR_AGENT': '1'},
          cursorAppRunning: false,
        ).target ==
        openInCursorIde,
    'plan cursor-ide',
  );
  _check(
    planPickerOpen(url, env: const {}, cursorAppRunning: false).target ==
        openInChrome,
    'plan chrome',
  );

  final uri = cursorSimpleBrowserUri(url);
  _check(uri.startsWith('vscode://vscode.simple-browser/show?url='), 'uri');
  _check(uri.contains(Uri.encodeComponent(url)), 'encoded url');
  _check(!uri.contains('\u2014'), 'uri em-dash');

  stdout.writeln('open page tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
