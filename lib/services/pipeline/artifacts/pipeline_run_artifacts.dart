import 'dart:collection' show UnmodifiableListView;

/// Artifacts produced by the current run only.
///
/// The output folder is keyed by version and build number, so it survives
/// re-runs. Distribution reads from this registry instead of listing that
/// folder, which is what keeps a previous run's APK, AAB or IPA from being
/// uploaded when this run failed to build one.
class PipelineRunArtifacts {
  PipelineRunArtifacts({required this.startedAt});

  /// Start of the run, used to reject build outputs left by earlier runs.
  final DateTime startedAt;

  final _paths = <String>[];

  late final UnmodifiableListView<String> paths = UnmodifiableListView(_paths);

  bool get isEmpty => _paths.isEmpty;

  void addAll(Iterable<String> collected) => _paths.addAll(collected);
}
