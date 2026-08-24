import 'dart:io';

import '../../io_helpers.dart';

void main() {
  final basic = parseCliFlags([
    '--log',
    '/tmp/logs.txt',
    '--success=false',
    '--dry-run',
    '--file',
    'a.apk',
    '--file',
    'b.apk',
  ]);
  _check(basic['log'] == '/tmp/logs.txt', 'value flag');
  _check(basic['success'] == 'false', 'equals form');
  _check(basic['dry-run'] == 'true', 'bare flag');
  _check(basic['files'] == 'a.apk\nb.apk', 'repeated files');

  // A missing value must never swallow the next flag.
  final greedy = parseCliFlags(['--log', '--output-dir', '/tmp/out']);
  _check(greedy['log'] == 'true', 'missing value stays a bare flag');
  _check(greedy['output-dir'] == '/tmp/out', 'next flag survives');

  final trailing = parseCliFlags(['--number']);
  _check(trailing['number'] == 'true', 'trailing flag');

  final empty = parseCliFlags(['--current', '']);
  _check(empty.containsKey('current'), 'empty value is still present');
  _check(empty['current'] == '', 'empty value kept');

  _check(parseCliFlags(['-h'])['help'] == 'true', 'short help');
  _check(parseCliFlags(['--help'])['help'] == 'true', 'long help');
  _check(parseCliFlags(['stray', 'words']).isEmpty, 'ignore positionals');

  _check(flagString(basic, 'log') == '/tmp/logs.txt', 'flagString');
  _check(flagString(basic, 'missing', 'fallback') == 'fallback', 'fallback');
  _check(flagString({'a': '  '}, 'a', 'fb') == 'fb', 'blank falls back');
  _check(!flagBool(basic, 'success', fallback: true), 'false wins');
  _check(flagBool(basic, 'missing', fallback: true), 'bool fallback');
  _check(flagBool(basic, 'dry-run'), 'bare flag is true');
  _check(flagInt({'n': '7'}, 'n', 2) == 7, 'flagInt');
  _check(flagInt({'n': 'x'}, 'n', 2) == 2, 'flagInt fallback');
  _check(flagInt({'n': '0'}, 'n', 2, min: 1) == 1, 'flagInt min');

  _check(csvValues('a, b ,,c').join('|') == 'a|b|c', 'csv trims and drops');
  _check(csvValues('a\nb').join('|') == 'a|b', 'csv newlines');
  _check(csvValues('  ').isEmpty, 'csv empty');

  final root = workspaceRoot();
  _check(dirExists(pathJoin(root, 'tool')), 'workspace has tool');
  _check(fileExists(pathJoin(root, 'pubspec.yaml')), 'workspace has pubspec');
  _check(
    resolveAgentPath(null, 'progress.json') ==
        pathJoin(root, '.fluship-agent', 'progress.json'),
    'default agent path',
  );
  _check(
    resolveAgentPath('.fluship-agent/progress.json', 'progress.json') ==
        pathJoin(root, '.fluship-agent/progress.json'),
    'relative anchors to workspace',
  );
  _check(
    resolveAgentPath('/tmp/progress.json', 'progress.json') ==
        '/tmp/progress.json',
    'absolute is kept',
  );

  stdout.writeln('io helpers tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
