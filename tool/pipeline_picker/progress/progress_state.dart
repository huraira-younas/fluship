import '../io_helpers.dart';
import 'progress.dart';

class UploadProgressInfo {
  const UploadProgressInfo({
    required this.id,
    required this.file,
    this.bytes,
    this.total,
    this.percent,
    this.fileIndex,
    this.fileCount,
  });

  final String id;
  final String file;
  final int? bytes;
  final int? total;
  final int? percent;
  final int? fileIndex;
  final int? fileCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'file': file,
    if (bytes != null) 'bytes': bytes,
    if (total != null) 'total': total,
    if (percent != null) 'percent': percent,
    if (fileIndex != null) 'fileIndex': fileIndex,
    if (fileCount != null) 'fileCount': fileCount,
  };

  factory UploadProgressInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UploadProgressInfo(id: '', file: '');
    return UploadProgressInfo(
      id: asString(json['id']),
      file: asString(json['file']),
      bytes: asInt(json['bytes']),
      total: asInt(json['total']),
      percent: asInt(json['percent']),
      fileIndex: asInt(json['fileIndex']),
      fileCount: asInt(json['fileCount']),
    );
  }

  String get label {
    if (file.isEmpty && percent == null) return '';
    final pct = percent == null ? '' : '$percent%';
    final name = file.isEmpty ? '' : file;
    final bits = [if (pct.isNotEmpty) pct, if (name.isNotEmpty) name];
    return bits.join(' ');
  }
}

class PipelineProgressState {
  const PipelineProgressState({
    this.app = '',
    this.version = '',
    this.buildNumber = '',
    this.now = '',
    this.elapsedJob = '',
    this.elapsedRun = '',
    this.note = '',
    this.selected = const [],
    this.done = const [],
    this.results = const {},
    this.times = const {},
    this.upload,
    this.idle = false,
    this.jobStartedAt,
    this.runStartedAt,
  });

  final String app;
  final String version;
  final String buildNumber;
  final String now;
  final String elapsedJob;
  final String elapsedRun;
  final String note;
  final List<String> selected;
  final List<String> done;
  final Map<String, String> results;
  final Map<String, String> times;
  final UploadProgressInfo? upload;
  final bool idle;
  final DateTime? jobStartedAt;
  final DateTime? runStartedAt;

  bool get isShareBusy => now == 'whatsappShare';

  PipelineProgressState copyWith({
    String? app,
    String? version,
    String? buildNumber,
    String? now,
    String? elapsedJob,
    String? elapsedRun,
    String? note,
    List<String>? selected,
    List<String>? done,
    Map<String, String>? results,
    Map<String, String>? times,
    UploadProgressInfo? upload,
    bool clearUpload = false,
    bool? idle,
    DateTime? jobStartedAt,
    DateTime? runStartedAt,
    bool clearJobStartedAt = false,
  }) {
    return PipelineProgressState(
      app: app ?? this.app,
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      now: now ?? this.now,
      elapsedJob: elapsedJob ?? this.elapsedJob,
      elapsedRun: elapsedRun ?? this.elapsedRun,
      note: note ?? this.note,
      selected: selected ?? this.selected,
      done: done ?? this.done,
      results: results ?? this.results,
      times: times ?? this.times,
      upload: clearUpload ? null : upload ?? this.upload,
      idle: idle ?? this.idle,
      jobStartedAt: clearJobStartedAt
          ? null
          : jobStartedAt ?? this.jobStartedAt,
      runStartedAt: runStartedAt ?? this.runStartedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'app': app,
    'version': version,
    'buildNumber': buildNumber,
    'now': now,
    'elapsedJob': elapsedJob,
    'elapsedRun': elapsedRun,
    'note': note,
    'selected': selected,
    'done': done,
    'results': results,
    'times': times,
    'idle': idle,
    if (upload != null) 'upload': upload!.toJson(),
    if (jobStartedAt != null)
      'jobStartedAt': jobStartedAt!.toUtc().toIso8601String(),
    if (runStartedAt != null)
      'runStartedAt': runStartedAt!.toUtc().toIso8601String(),
  };

  factory PipelineProgressState.fromJson(Map<String, dynamic> json) {
    final uploadRaw = json['upload'];
    return PipelineProgressState(
      app: asString(json['app']),
      version: asString(json['version']),
      buildNumber: asString(json['buildNumber']),
      now: asString(json['now']),
      elapsedJob: asString(json['elapsedJob']),
      elapsedRun: asString(json['elapsedRun']),
      note: asString(json['note']),
      selected: asStringList(json['selected']),
      done: asStringList(json['done']),
      results: _stringMap(json['results']),
      times: _stringMap(json['times']),
      idle: json['idle'] == true,
      upload: uploadRaw is Map
          ? UploadProgressInfo.fromJson(Map<String, dynamic>.from(uploadRaw))
          : null,
      jobStartedAt: DateTime.tryParse(asString(json['jobStartedAt']))?.toUtc(),
      runStartedAt: DateTime.tryParse(asString(json['runStartedAt']))?.toUtc(),
    );
  }
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if ('${entry.key}'.trim().isNotEmpty) '${entry.key}': '${entry.value}',
  };
}

PipelineProgressState loadProgressState(String path) {
  final json = readJsonFile(path);
  if (json.isEmpty) return const PipelineProgressState();
  return PipelineProgressState.fromJson(json);
}

void saveProgressState(String path, PipelineProgressState state) {
  writeJsonFile(path, state.toJson());
}

PipelineProgressState markProgressIdle(PipelineProgressState state) {
  return state.copyWith(
    now: '',
    idle: true,
    note: '',
    clearUpload: true,
    clearJobStartedAt: true,
    elapsedJob: '',
  );
}

void writeProgressIdle(String path) {
  if (path.trim().isEmpty) return;
  final current = loadProgressState(path);
  saveProgressState(path, markProgressIdle(current));
}

/// Clears the board before a run starts. A board update only replaces `done`,
/// `results`, and `times` when the new value is non-empty, so without this the
/// first board of a run shows the previous run's rows and run clock.
void resetProgressForRun(String path) {
  if (path.trim().isEmpty) return;
  saveProgressState(path, const PipelineProgressState(idle: true));
}

String formatElapsed(Duration duration) {
  final secs = duration.inSeconds;
  if (secs < 0) return '0s';
  if (secs < 60) return '${secs}s';
  final minutes = secs ~/ 60;
  final rest = secs % 60;
  if (minutes < 60) return rest == 0 ? '${minutes}m' : '${minutes}m${rest}s';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return mins == 0 ? '${hours}h' : '${hours}h${mins}m';
}

Duration? jobElapsed({
  required PipelineProgressState state,
  required DateTime now,
}) {
  final started = state.jobStartedAt;
  if (started == null) return null;
  return now.toUtc().difference(started);
}

Duration? runElapsed({
  required PipelineProgressState state,
  required DateTime now,
}) {
  final started = state.runStartedAt;
  if (started == null) return null;
  return now.toUtc().difference(started);
}

class ProgressWriteGate {
  ProgressWriteGate({this.minGap = const Duration(milliseconds: 250)});

  final Duration minGap;
  DateTime? _last;
  int? _lastPercent;

  bool allow(int? percent, DateTime now) {
    if (percent != _lastPercent) {
      _lastPercent = percent;
      _last = now;
      return true;
    }
    if (_last == null || now.difference(_last!) >= minGap) {
      _last = now;
      return true;
    }
    return false;
  }
}

PipelineProgressState applyBoardUpdate({
  required PipelineProgressState existing,
  required DateTime now,
  String? current,
  String app = '',
  String version = '',
  String buildNumber = '',
  String note = '',
  List<String> selected = const [],
  List<String> done = const [],
  Map<String, String> results = const {},
  Map<String, String> times = const {},
}) {
  final nowId = current == null
      ? existing.now
      : current.trim().isEmpty
      ? ''
      : normalizeStepId(current);
  final nowChanged = nowId != existing.now;
  final runStarted = existing.runStartedAt ?? now;
  final jobStarted = nowId.isEmpty
      ? null
      : (nowChanged ? now : existing.jobStartedAt ?? now);
  final jobFor = jobStarted == null ? null : now.difference(jobStarted);
  final keepUpload =
      !nowChanged && nowId.isNotEmpty && existing.upload?.id == nowId;
  return PipelineProgressState(
    app: app.isNotEmpty ? app : existing.app,
    version: version.isNotEmpty ? version : existing.version,
    buildNumber: buildNumber.isNotEmpty ? buildNumber : existing.buildNumber,
    now: nowId,
    elapsedJob: jobFor == null ? '' : formatElapsed(jobFor),
    elapsedRun: formatElapsed(now.difference(runStarted)),
    note: note.isNotEmpty ? note : existing.note,
    selected: selected.isNotEmpty ? selected : existing.selected,
    done: done.isNotEmpty ? done : existing.done,
    results: results.isNotEmpty ? results : existing.results,
    times: times.isNotEmpty ? times : existing.times,
    upload: keepUpload ? existing.upload : null,
    idle: nowId.isEmpty,
    jobStartedAt: jobStarted,
    runStartedAt: runStarted,
  );
}

void patchUploadProgress({
  required String path,
  required UploadProgressInfo upload,
  String? note,
}) {
  if (path.trim().isEmpty) return;
  final current = loadProgressState(path);
  saveProgressState(
    path,
    current.copyWith(upload: upload, note: note ?? current.note, idle: false),
  );
}

String progressSnapshotLine(PipelineProgressState state) {
  final upload = state.upload?.label ?? '';
  return [
    '[progress]',
    if (state.now.isNotEmpty) 'NOW ${state.now}',
    if (state.elapsedJob.isNotEmpty) state.elapsedJob,
    if (upload.isNotEmpty) upload,
    if (state.note.isNotEmpty) state.note,
  ].join('  ');
}
