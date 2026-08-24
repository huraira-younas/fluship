import 'dart:io';

import 'cache_io.dart';
import 'catalog.dart';
import 'io_helpers.dart';
import 'readiness.dart';
import 'whatsapp.dart';

void main() {
  _hostCatalog();
  _pubspecVersion();
  _rememberProject();
  _mutex();
  _readinessCases();
  _parentDeps();
  _stripIosOnWindowsCache();
  _cacheWhatsApp();
  _noEmDash();
  stdout.writeln('pipeline_picker tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}

void _hostCatalog() {
  final windows = Catalog.forHost(isMacOS: false);
  final mac = Catalog.forHost(isMacOS: true);
  final winIds = {for (final step in windows) step.id};
  final macIds = {for (final step in mac) step.id};

  for (final id in Catalog.iosIds) {
    _check(!winIds.contains(id), 'Windows catalog must omit $id');
    _check(macIds.contains(id), 'macOS catalog must include $id');
  }

  const androidFull = [
    'buildAab',
    'collectAab',
    'buildApk',
    'buildSplits',
    'collectApk',
    'distPlayProduction',
    'distPlayInternal',
    'distDrive',
    'slackNotify',
    'report',
    'whatsappShare',
    'clean',
    'pubGet',
    'format',
  ];
  for (final id in androidFull) {
    _check(winIds.contains(id), 'Windows catalog must include $id');
    _check(macIds.contains(id), 'macOS catalog must include $id');
  }
}

void _pubspecVersion() {
  final parsed = parsePubspecVersion('name: x\nversion: 2.3.4+9\n');
  _check(parsed.$1 == '2.3.4', 'version parse');
  _check(parsed.$2 == '9', 'build parse');
  final plain = parsePubspecVersion('version: 1.0.0\n');
  _check(plain.$1 == '1.0.0' && plain.$2.isEmpty, 'version without build');
}

void _rememberProject() {
  final first = rememberProject(const [], '/tmp/app');
  _check(first.length == 1, 'remember first');
  _check(first.first.endsWith('app'), 'remember abs');
  final again = rememberProject(first, '/tmp/app');
  _check(again.length == 1, 'remember unique');
}

void _mutex() {
  _check(
    Catalog.mutexConflict(['pubGet', 'pubUpgrade']).length == 2,
    'pub mutex',
  );
  _check(Catalog.mutexConflict(['pubGet', 'clean']).isEmpty, 'no mutex');
  _check(
    Catalog.mutexConflict(['powerShutdown', 'powerSleep']).length == 2,
    'power mutex',
  );
}

void _readinessCases() {
  final mac = Catalog.forHost(isMacOS: true);
  final empty = evaluateReadiness(
    catalog: mac,
    project: ProjectFacts.empty,
    secrets: SecretsFacts.empty,
    selected: const {},
  );
  for (final step in empty) {
    _check(!step.enabled, '${step.id} blocked without project');
    _check(step.reason == reasonSelectProject, '${step.id} select reason');
  }

  final root = Directory.systemTemp.createTempSync('fluship-picker-');
  try {
    final noPub = Directory(pathJoin(root.path, 'nopub'))..createSync();
    final noPubFacts = ProjectFacts.inspect(noPub.path);
    _check(!noPubFacts.isValidFlutterProject, 'no pubspec invalid');
    final noPubReady = evaluateReadiness(
      catalog: mac,
      project: noPubFacts,
      secrets: SecretsFacts.empty,
      selected: const {},
    );
    _check(
      noPubReady.every((step) => step.reason == reasonNoPubspec),
      'no pubspec reason',
    );

    final android = _flutterProject(root.path, 'android-app', android: true);
    final androidReady = evaluateReadiness(
      catalog: Catalog.forHost(isMacOS: false),
      project: ProjectFacts.inspect(android),
      secrets: SecretsFacts.empty,
      selected: {'buildAab'},
    );
    final androidMap = {for (final step in androidReady) step.id: step};
    _check(androidMap['buildAab']!.enabled, 'buildAab ready');
    _check(androidMap['collectAab']!.enabled, 'collectAab after buildAab');
    _check(!androidMap['distPlayProduction']!.enabled, 'play needs secrets');
    _check(
      androidMap['distPlayProduction']!.reason == reasonPlaySecrets,
      'play reason',
    );
    _check(!androidMap.containsKey('podInstall'), 'windows omits ios');
    _check(
      androidMap['preCommit']!.reason == reasonNoGit,
      'git reason without .git',
    );
    _check(
      androidMap.containsKey('whatsappShare'),
      'windows has whatsappShare',
    );
    _check(
      androidMap['whatsappShare']!.reason == reasonWhatsAppNumber,
      'whatsapp needs number',
    );

    final ios = _flutterProject(root.path, 'ios-app', ios: true, git: true);
    final iosReady = evaluateReadiness(
      catalog: mac,
      project: ProjectFacts.inspect(ios),
      secrets: SecretsFacts.empty,
      selected: const {},
    );
    final iosMap = {for (final step in iosReady) step.id: step};
    _check(iosMap['podInstall']!.enabled, 'podInstall when ios exists');
    _check(!iosMap['buildAab']!.enabled, 'android missing');
    _check(iosMap['buildAab']!.reason == reasonNoAndroid, 'android reason');
    _check(!iosMap['distAppStore']!.enabled, 'app store secrets');
    _check(
      iosMap['distAppStore']!.reason == reasonNeedCollectIpa ||
          iosMap['distAppStore']!.reason == reasonAppStoreSecrets,
      'app store blocked',
    );
    _check(iosMap['preCommit']!.enabled, 'git ready');

    final sa = File(pathJoin(root.path, 'sa.json'))
      ..writeAsStringSync('{"type":"service_account"}');
    final p8 = File(pathJoin(root.path, 'key.p8'))..writeAsStringSync('key');
    final secrets = SecretsFacts.fromJson({
      'playSaJsonPath': sa.path,
      'playPackageName': 'com.example.app',
      'appStoreIssuerId': 'issuer',
      'appStoreApiKeyId': 'key',
      'appStoreApiKeyPath': p8.path,
      'driveOauthJson': '{"installed":{}}',
      'slackWebhookUrl': 'https://hooks.slack.com/x',
      'gmailAddress': 'a@b.com',
      'appPassword': 'pw',
    });
    _check(secrets.canPlay, 'play secrets');
    _check(secrets.canAppStore, 'app store secrets');
    _check(secrets.canDrive, 'drive secrets');
    _check(secrets.canSlack, 'slack secrets');
    _check(secrets.canReport, 'report secrets');

    final both = _flutterProject(
      root.path,
      'full-app',
      android: true,
      ios: true,
      git: true,
    );
    final full = evaluateReadiness(
      catalog: mac,
      project: ProjectFacts.inspect(both),
      secrets: secrets,
      selected: {
        'buildAab',
        'collectAab',
        'buildApk',
        'collectApk',
        'buildIpa',
        'collectIpa',
        'distDrive',
      },
      whatsappNumber: defaultWhatsAppNumber,
    );
    final fullMap = {for (final step in full) step.id: step};
    _check(fullMap['distPlayProduction']!.enabled, 'play enabled');
    _check(fullMap['distAppStore']!.enabled, 'app store enabled');
    _check(fullMap['distDrive']!.enabled, 'drive enabled');
    _check(fullMap['slackNotify']!.enabled, 'slack enabled');
    _check(fullMap['report']!.enabled, 'report enabled');
    _check(fullMap['whatsappShare']!.enabled, 'whatsapp enabled');
  } finally {
    root.deleteSync(recursive: true);
  }
}

void _parentDeps() {
  final root = Directory.systemTemp.createTempSync('fluship-parent-');
  try {
    final path = _flutterProject(root.path, 'app', android: true, ios: true);
    final catalog = Catalog.forHost(isMacOS: true);
    final project = ProjectFacts.inspect(path);
    final secrets = SecretsFacts.fromJson({
      'driveOauthJson': '{"installed":{}}',
      'slackWebhookUrl': 'https://hooks.slack.com/x',
    });
    final none = {
      for (final step in evaluateReadiness(
        catalog: catalog,
        project: project,
        secrets: secrets,
        selected: const {},
      ))
        step.id: step,
    };
    _check(
      none['collectAab']!.reason == reasonNeedBuildAab,
      'collectAab parent',
    );
    _check(
      none['collectApk']!.reason == reasonNeedApkBuild,
      'collectApk parent',
    );
    _check(
      none['collectIpa']!.reason == reasonNeedBuildIpa,
      'collectIpa parent',
    );
    _check(none['distDrive']!.reason == reasonNeedCollectApk, 'drive parent');
    _check(
      none['slackNotify']!.reason == reasonNeedDriveAndApk,
      'slack parents',
    );
    final stable = stabilizeReadiness(
      catalog: catalog,
      project: project,
      secrets: secrets,
      selected: const ['collectAab', 'buildAab'],
    );
    _check(stable.checked.contains('buildAab'), 'keep parent');
    _check(stable.checked.contains('collectAab'), 'keep child after parent');
    final orphan = stabilizeReadiness(
      catalog: catalog,
      project: project,
      secrets: secrets,
      selected: const ['collectAab'],
    );
    _check(!orphan.checked.contains('collectAab'), 'drop orphan collect');
  } finally {
    root.deleteSync(recursive: true);
  }
}

void _stripIosOnWindowsCache() {
  final selected = hostSelectedIds(
    selected: [
      'buildAab',
      'podInstall',
      'buildIpa',
      'collectIpa',
      'distAppStore',
      'report',
    ],
    isMacOS: false,
  );
  _check(selected.contains('buildAab'), 'keep android');
  _check(selected.contains('report'), 'keep report');
  for (final id in Catalog.iosIds) {
    _check(!selected.contains(id), 'strip $id on Windows cache');
  }
}

void _cacheWhatsApp() {
  final root = Directory.systemTemp.createTempSync('fluship-cache-');
  try {
    final path = pathJoin(root.path, 'pipeline-cache.json');
    final cache = PipelineCache.empty().copyWith(
      whatsappNumber: defaultWhatsAppNumber,
      selected: const ['whatsappShare'],
    );
    savePipelineCache(path, cache);
    final loaded = loadPipelineCache(path);
    _check(loaded.whatsappNumber == defaultWhatsAppNumber, 'cache number');
    _check(loaded.selected.contains('whatsappShare'), 'cache selected');
  } finally {
    root.deleteSync(recursive: true);
  }
}

void _noEmDash() {
  const needle = '\u2014';
  for (final text in catalogUserFacingStrings) {
    _check(!text.contains(needle), 'reason has em-dash: $text');
  }
  for (final step in Catalog.steps) {
    _check(!step.label.contains(needle), 'label has em-dash: ${step.id}');
    _check(!step.title.contains(needle), 'title has em-dash: ${step.id}');
    _check(!step.blurb.contains(needle), 'blurb has em-dash: ${step.id}');
    _check(!step.groupId.contains(needle), 'group id has em-dash');
  }
  for (final group in Catalog.groupOrder) {
    _check(!group.title.contains(needle), 'group title has em-dash');
  }

  final here = File.fromUri(Platform.script).parent;
  final files = [
    ...here.listSync(recursive: true).whereType<File>(),
    File(pathJoin(here.parent.path, 'pipeline_picker.dart')),
    File(pathJoin(here.parent.path, 'whatsapp_share.dart')),
    File(pathJoin(here.parent.path, 'pipeline_cleanup.dart')),
    File(pathJoin(here.parent.path, 'pipeline_progress.dart')),
    File(pathJoin(here.parent.path, 'pipeline_warmup.dart')),
    File(pathJoin(here.parent.path, 'pipeline_report.py')),
    File(pathJoin(here.parent.path, 'pipeline_report_test.py')),
    File(pathJoin(here.parent.path, 'whatsapp_send.py')),
    File(pathJoin(here.parent.path, 'whatsapp_send_test.py')),
    File(pathJoin(here.parent.parent.path, 'AGENTS.md')),
    File(
      pathJoin(
        here.parent.parent.path,
        '.cursor',
        'skills',
        'fluship-pipeline',
        'SKILL.md',
      ),
    ),
  ];
  for (final file in files) {
    if (!file.path.endsWith('.dart') &&
        !file.path.endsWith('.html') &&
        !file.path.endsWith('.css') &&
        !file.path.endsWith('.js') &&
        !file.path.endsWith('.md') &&
        !file.path.endsWith('.py')) {
      continue;
    }
    _check(
      !file.readAsStringSync().contains(needle),
      'em-dash in ${file.path}',
    );
  }
}

String _flutterProject(
  String root,
  String name, {
  bool android = false,
  bool ios = false,
  bool git = false,
}) {
  final dir = Directory(pathJoin(root, name))..createSync();
  File(
    pathJoin(dir.path, 'pubspec.yaml'),
  ).writeAsStringSync('name: $name\nversion: 1.2.3+4\n');
  if (android) Directory(pathJoin(dir.path, 'android')).createSync();
  if (ios) Directory(pathJoin(dir.path, 'ios')).createSync();
  if (git) Directory(pathJoin(dir.path, '.git')).createSync();
  return dir.path;
}
