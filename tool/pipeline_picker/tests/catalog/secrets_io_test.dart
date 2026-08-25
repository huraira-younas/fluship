import 'dart:io';

import '../../catalog/secrets_io.dart';
import '../../io_helpers.dart';

void main() {
  _uniqueKeys();
  _hostFilter();
  _panelShape();
  _mergeRules();
  _roundTrip();
  _noEmDash();
  stdout.writeln('pipeline secrets tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}

void _uniqueKeys() {
  final seen = <String>{};
  for (final field in secretFields) {
    _check(seen.add(field.key), 'duplicate secret key: ${field.key}');
    _check(field.label.isNotEmpty, '${field.key} needs a label');
    if (field.isFile) {
      _check(field.prompt.isNotEmpty, '${field.key} needs a browse prompt');
    }
  }
  _check(seen.contains('playSaJsonPath'), 'play key missing');
  _check(seen.contains('slackWebhookUrl'), 'slack key missing');
  _check(seen.contains('emailRecipient'), 'recipient field missing');
}

void _hostFilter() {
  final mac = {for (final g in secretGroupsForHost(isMacOS: true)) g.id};
  final windows = {for (final g in secretGroupsForHost(isMacOS: false)) g.id};
  _check(mac.contains('appStore'), 'macOS shows App Store');
  _check(!windows.contains('appStore'), 'Windows hides App Store');
  _check(windows.contains('play'), 'Windows shows Play');
}

void _panelShape() {
  final root = Directory.systemTemp.createTempSync('fluship-secrets-');
  try {
    final sa = File(pathJoin(root.path, 'sa.json'))
      ..writeAsStringSync('{"type":"service_account"}');
    final panel = secretsPanelJson(
      secrets: {
        'playPackageName': 'com.example.app',
        'playSaJsonPath': sa.path,
        'appPassword': 'super secret',
        'gmailAddress': 'you@gmail.com',
        'driveOauthJson': pathJoin(root.path, 'gone.json'),
      },
      cacheValues: {'emailRecipient': 'reports@example.com'},
      isMacOS: false,
    );
    final groups = (panel['groups'] as List).cast<Map<String, dynamic>>();
    final byId = {for (final group in groups) group['id'] as String: group};
    _check(byId['play']!['ready'] == true, 'play ready with both keys');
    _check(byId['slack']!['ready'] == false, 'slack not ready');
    _check(byId['drive']!['ready'] == false, 'drive not ready when file gone');

    final fields = <String, Map<String, dynamic>>{
      for (final group in groups)
        for (final field in (group['fields'] as List))
          (field as Map<String, dynamic>)['key'] as String: field,
    };
    _check(fields['appPassword']!['value'] == '', 'password never echoed');
    _check(fields['appPassword']!['saved'] == true, 'password marked saved');
    _check(
      fields['playSaJsonPath']!['missingFile'] == false,
      'existing file is not flagged',
    );
    _check(
      fields['driveOauthJson']!['missingFile'] == true,
      'missing file is flagged',
    );
    _check(
      fields['emailRecipient']!['value'] == 'reports@example.com',
      'recipient comes from the cache',
    );
  } finally {
    root.deleteSync(recursive: true);
  }
}

void _mergeRules() {
  const existing = {'appPassword': 'keep me', 'playPackageName': 'com.old.app'};
  final blank = mergeSecrets(
    existing: existing,
    incoming: {'appPassword': '', 'playPackageName': ''},
  );
  _check(blank['appPassword'] == 'keep me', 'blank password keeps the old one');
  _check(!blank.containsKey('playPackageName'), 'blank text clears its key');

  final edited = mergeSecrets(
    existing: existing,
    incoming: {'appPassword': ' new pass ', 'emailRecipient': 'a@b.com'},
  );
  _check(edited['appPassword'] == 'new pass', 'password trimmed and replaced');
  _check(!edited.containsKey('emailRecipient'), 'cache field stays out');

  final untouched = mergeSecrets(existing: existing, incoming: const {});
  _check(untouched['playPackageName'] == 'com.old.app', 'absent key untouched');
}

void _roundTrip() {
  final root = Directory.systemTemp.createTempSync('fluship-secrets-write-');
  try {
    final path = pathJoin(root.path, 'secrets.json');
    writeSecretsFile(path, {'slackWebhookUrl': 'https://hooks.slack.com/x'});
    final loaded = readJsonFile(path);
    _check(loaded['slackWebhookUrl'] == 'https://hooks.slack.com/x', 'reload');
    if (!Platform.isWindows) {
      final mode = File(path).statSync().mode & 0x1FF;
      _check(mode == 0x180, 'secrets file is owner-only');
    }
  } finally {
    root.deleteSync(recursive: true);
  }
}

void _noEmDash() {
  const needle = '\u2014';
  for (final group in secretGroups) {
    _check(!group.title.contains(needle), 'em-dash in ${group.id} title');
    _check(!group.blurb.contains(needle), 'em-dash in ${group.id} blurb');
    for (final field in group.fields) {
      _check(!field.label.contains(needle), 'em-dash in ${field.key} label');
      _check(!field.hint.contains(needle), 'em-dash in ${field.key} hint');
    }
  }
}
