import '../io_helpers.dart';
import 'catalog.dart';

class PipelineCache {
  PipelineCache({
    required this.selected,
    required this.version,
    required this.buildNumber,
    required this.gitBranch,
    required this.targetProjectPath,
    required this.recentProjectPaths,
    required this.preCommitMessage,
    required this.postCommitMessage,
    required this.releaseNotes,
    required this.emailRecipient,
    required this.playTrack,
    required this.powerAction,
    required this.powerDelaySeconds,
    required this.driveRecipients,
    required this.whatsappNumber,
    required this.updatedAt,
    this.raw = const {},
  });

  final List<String> selected;
  final String version;
  final String buildNumber;
  final String gitBranch;
  final String targetProjectPath;
  final List<String> recentProjectPaths;
  final String preCommitMessage;
  final String postCommitMessage;
  final String releaseNotes;
  final String emailRecipient;
  final String? playTrack;
  final String? powerAction;
  final int powerDelaySeconds;
  final List<String> driveRecipients;
  final String whatsappNumber;
  final String updatedAt;
  final Map<String, dynamic> raw;

  bool get hasSavedProject => targetProjectPath.trim().isNotEmpty;

  factory PipelineCache.empty() {
    return PipelineCache(
      selected: const [],
      version: '',
      buildNumber: '',
      gitBranch: 'master',
      targetProjectPath: '',
      recentProjectPaths: const [],
      preCommitMessage: '{version} cleanup',
      postCommitMessage: '{version} release',
      releaseNotes: '',
      emailRecipient: '',
      playTrack: null,
      powerAction: null,
      powerDelaySeconds: 10,
      driveRecipients: const [],
      whatsappNumber: '',
      updatedAt: '',
    );
  }

  factory PipelineCache.fromJson(Map<String, dynamic> json) {
    return PipelineCache(
      selected: asStringList(json['selected']),
      version: asString(json['version']),
      buildNumber: asString(json['buildNumber']),
      gitBranch: asString(json['gitBranch'], 'master'),
      targetProjectPath: asString(json['targetProjectPath']),
      recentProjectPaths: asStringList(json['recentProjectPaths']),
      preCommitMessage: asString(json['preCommitMessage'], '{version} cleanup'),
      postCommitMessage: asString(
        json['postCommitMessage'],
        '{version} release',
      ),
      releaseNotes: asString(json['releaseNotes']),
      emailRecipient: asString(json['emailRecipient']),
      playTrack: _nullableString(json['playTrack']),
      powerAction: _nullableString(json['powerAction']),
      powerDelaySeconds: asInt(json['powerDelaySeconds']) ?? 10,
      driveRecipients: asStringList(json['driveRecipients']),
      whatsappNumber: asString(json['whatsappNumber']),
      updatedAt: asString(json['updatedAt']),
      raw: json,
    );
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  PipelineCache copyWith({
    List<String>? selected,
    String? version,
    String? buildNumber,
    String? gitBranch,
    String? targetProjectPath,
    List<String>? recentProjectPaths,
    String? preCommitMessage,
    String? postCommitMessage,
    String? releaseNotes,
    String? emailRecipient,
    String? playTrack,
    String? powerAction,
    int? powerDelaySeconds,
    List<String>? driveRecipients,
    String? whatsappNumber,
    String? updatedAt,
    bool clearPlayTrack = false,
    bool clearPowerAction = false,
  }) {
    return PipelineCache(
      selected: selected ?? this.selected,
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      gitBranch: gitBranch ?? this.gitBranch,
      targetProjectPath: targetProjectPath ?? this.targetProjectPath,
      recentProjectPaths: recentProjectPaths ?? this.recentProjectPaths,
      preCommitMessage: preCommitMessage ?? this.preCommitMessage,
      postCommitMessage: postCommitMessage ?? this.postCommitMessage,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      emailRecipient: emailRecipient ?? this.emailRecipient,
      playTrack: clearPlayTrack ? null : (playTrack ?? this.playTrack),
      powerAction: clearPowerAction ? null : (powerAction ?? this.powerAction),
      powerDelaySeconds: powerDelaySeconds ?? this.powerDelaySeconds,
      driveRecipients: driveRecipients ?? this.driveRecipients,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      updatedAt: updatedAt ?? this.updatedAt,
      raw: raw,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...raw,
      'selected': selected,
      'version': version,
      'buildNumber': buildNumber,
      'gitBranch': gitBranch,
      'targetProjectPath': targetProjectPath,
      'recentProjectPaths': recentProjectPaths,
      'preCommitMessage': preCommitMessage,
      'postCommitMessage': postCommitMessage,
      'releaseNotes': releaseNotes,
      'emailRecipient': emailRecipient,
      'playTrack': playTrack,
      'powerAction': powerAction,
      'powerDelaySeconds': powerDelaySeconds,
      'driveRecipients': driveRecipients,
      'whatsappNumber': whatsappNumber,
      'updatedAt': updatedAt,
    };
  }
}

PipelineCache loadPipelineCache(String path) {
  return PipelineCache.fromJson(readJsonFile(path));
}

void savePipelineCache(String path, PipelineCache cache) {
  writeJsonFile(path, cache.toJson());
}

List<String> hostSelectedIds({
  required Iterable<String> selected,
  required bool isMacOS,
}) {
  final allowed = Catalog.idsForHost(isMacOS: isMacOS);
  return [
    for (final id in selected)
      if (allowed.contains(id)) id,
  ];
}

List<String> rememberProject(List<String> recents, String projectPath) {
  final abs = absolutePath(projectPath);
  if (abs.isEmpty) return recents;
  final next = <String>[abs];
  for (final item in recents) {
    final value = absolutePath(item);
    if (value.isEmpty || value == abs) continue;
    next.add(value);
    if (next.length >= 8) break;
  }
  return next;
}

String? playTrackFor(Iterable<String> selected) {
  if (selected.contains('distPlayInternal')) return 'internal';
  if (selected.contains('distPlayProduction')) return 'production';
  return null;
}

String? powerActionFor(Iterable<String> selected) {
  if (selected.contains('powerShutdown')) return 'shutdown';
  if (selected.contains('powerSleep')) return 'sleep';
  if (selected.contains('powerLock')) return 'lock';
  return null;
}
