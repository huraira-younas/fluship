import 'dart:io';

import '../io_helpers.dart';
import '../share/whatsapp.dart';
import 'catalog.dart';

class ProjectFacts {
  const ProjectFacts({
    required this.path,
    required this.hasProject,
    required this.hasPubspec,
    required this.hasGit,
    required this.hasAndroid,
    required this.hasIos,
    required this.version,
    required this.buildNumber,
  });

  final String path;
  final bool hasProject;
  final bool hasPubspec;
  final bool hasGit;
  final bool hasAndroid;
  final bool hasIos;
  final String version;
  final String buildNumber;

  bool get isValidFlutterProject => hasProject && hasPubspec;

  static const empty = ProjectFacts(
    path: '',
    hasProject: false,
    hasPubspec: false,
    hasGit: false,
    hasAndroid: false,
    hasIos: false,
    version: '',
    buildNumber: '',
  );

  static ProjectFacts inspect(String rawPath) {
    final path = absolutePath(rawPath);
    if (path.isEmpty || !dirExists(path)) return empty;
    final pubspec = File(pathJoin(path, 'pubspec.yaml'));
    final hasPubspec = pubspec.existsSync();
    var version = '';
    var buildNumber = '';
    if (hasPubspec) {
      final parsed = parsePubspecVersion(pubspec.readAsStringSync());
      version = parsed.$1;
      buildNumber = parsed.$2;
    }
    return ProjectFacts(
      path: path,
      hasProject: true,
      hasPubspec: hasPubspec,
      hasGit: dirExists(pathJoin(path, '.git')),
      hasAndroid: dirExists(pathJoin(path, 'android')),
      hasIos: dirExists(pathJoin(path, 'ios')),
      version: version,
      buildNumber: buildNumber,
    );
  }
}

class SecretsFacts {
  const SecretsFacts({
    required this.canPlay,
    required this.canAppStore,
    required this.canDrive,
    required this.canSlack,
    required this.canReport,
  });

  final bool canPlay;
  final bool canAppStore;
  final bool canDrive;
  final bool canSlack;
  final bool canReport;

  static const empty = SecretsFacts(
    canPlay: false,
    canAppStore: false,
    canDrive: false,
    canSlack: false,
    canReport: false,
  );

  factory SecretsFacts.fromJson(Map<String, dynamic> secrets) {
    final saPath = asString(secrets['playSaJsonPath']);
    final packageName = asString(secrets['playPackageName']);
    final issuer = asString(secrets['appStoreIssuerId']);
    final keyId = asString(secrets['appStoreApiKeyId']);
    final keyPath = asString(secrets['appStoreApiKeyPath']);
    return SecretsFacts(
      canPlay: packageName.isNotEmpty && fileExists(saPath),
      canAppStore: issuer.isNotEmpty && keyId.isNotEmpty && fileExists(keyPath),
      canDrive: secretFileOrJsonPresent(asString(secrets['driveOauthJson'])),
      canSlack: secretPresent(asString(secrets['slackWebhookUrl'])),
      canReport:
          secretPresent(asString(secrets['gmailAddress'])) &&
          secretPresent(asString(secrets['appPassword'])),
    );
  }
}

class StepReadiness {
  const StepReadiness({required this.id, required this.enabled, this.reason});

  final String id;
  final bool enabled;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'enabled': enabled,
    'reason': reason,
  };
}

(String, String) parsePubspecVersion(String source) {
  for (final rawLine in source.split('\n')) {
    final line = rawLine.trim();
    if (!line.startsWith('version:')) continue;
    final value = line.substring('version:'.length).trim();
    if (value.isEmpty) return ('', '');
    final plus = value.indexOf('+');
    if (plus < 0) return (value, '');
    return (value.substring(0, plus).trim(), value.substring(plus + 1).trim());
  }
  return ('', '');
}

List<StepReadiness> evaluateReadiness({
  required List<CatalogStep> catalog,
  required ProjectFacts project,
  required SecretsFacts secrets,
  required Set<String> selected,
  String whatsappNumber = '',
}) {
  return [
    for (final step in catalog)
      _evaluateStep(
        step: step,
        project: project,
        secrets: secrets,
        selected: selected,
        whatsappNumber: whatsappNumber,
      ),
  ];
}

StepReadiness _evaluateStep({
  required CatalogStep step,
  required ProjectFacts project,
  required SecretsFacts secrets,
  required Set<String> selected,
  required String whatsappNumber,
}) {
  if (!project.hasProject) {
    return StepReadiness(
      id: step.id,
      enabled: false,
      reason: reasonSelectProject,
    );
  }
  if (!project.hasPubspec) {
    return StepReadiness(id: step.id, enabled: false, reason: reasonNoPubspec);
  }

  final layerA = _layerAReason(step.id, project, secrets, whatsappNumber);
  if (layerA != null) {
    return StepReadiness(id: step.id, enabled: false, reason: layerA);
  }

  final parent = Catalog.parentRequirements[step.id];
  if (parent != null && !parent.isMet(selected)) {
    return StepReadiness(id: step.id, enabled: false, reason: parent.reason);
  }

  return StepReadiness(id: step.id, enabled: true);
}

String? _layerAReason(
  String id,
  ProjectFacts project,
  SecretsFacts secrets,
  String whatsappNumber,
) {
  const gitIds = {'preCommit', 'prePull', 'postCommit', 'postPush'};
  const androidIds = {
    'buildAab',
    'collectAab',
    'buildApk',
    'buildSplits',
    'collectApk',
    'distPlayProduction',
    'distPlayInternal',
    'distDrive',
    'slackNotify',
  };
  const iosIds = {'podInstall', 'buildIpa', 'collectIpa', 'distAppStore'};

  if (gitIds.contains(id) && !project.hasGit) return reasonNoGit;
  if (androidIds.contains(id) && !project.hasAndroid) return reasonNoAndroid;
  if (iosIds.contains(id) && !project.hasIos) return reasonNoIos;

  if ((id == 'distPlayProduction' || id == 'distPlayInternal') &&
      !secrets.canPlay) {
    return reasonPlaySecrets;
  }
  if (id == 'distAppStore' && !secrets.canAppStore) {
    return reasonAppStoreSecrets;
  }
  if (id == 'distDrive' && !secrets.canDrive) return reasonDriveSecrets;
  if (id == 'slackNotify' && !secrets.canSlack) return reasonSlackSecrets;
  if (id == 'report' && !secrets.canReport) return reasonReportSecrets;
  if (id == 'whatsappShare' && !isValidWhatsAppNumber(whatsappNumber)) {
    return reasonWhatsAppNumber;
  }
  return null;
}

Set<String> _enabledIds(List<StepReadiness> readiness) {
  return {
    for (final step in readiness)
      if (step.enabled) step.id,
  };
}

Set<String> filterSelected(
  Iterable<String> selected,
  List<StepReadiness> readiness,
) {
  final allowed = _enabledIds(readiness);
  return {
    for (final id in selected)
      if (allowed.contains(id)) id,
  };
}

({List<StepReadiness> rows, Set<String> checked}) stabilizeReadiness({
  required List<CatalogStep> catalog,
  required ProjectFacts project,
  required SecretsFacts secrets,
  required Iterable<String> selected,
  String whatsappNumber = '',
}) {
  var rows = evaluateReadiness(
    catalog: catalog,
    project: project,
    secrets: secrets,
    selected: selected.toSet(),
    whatsappNumber: whatsappNumber,
  );
  var checked = filterSelected(selected, rows);
  rows = evaluateReadiness(
    catalog: catalog,
    project: project,
    secrets: secrets,
    selected: checked,
    whatsappNumber: whatsappNumber,
  );
  return (rows: rows, checked: filterSelected(checked, rows));
}
