import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;

/// Artifacts produced by the current run only.
///
/// The output folder is keyed by version and build number, so it survives
/// re-runs. Distribution reads from this registry instead of listing that
/// folder, which is what keeps a previous run's APK, AAB or IPA from being
/// uploaded when this run failed to build one.
class PipelineRunArtifacts({
  /// Start of the run, used to reject build outputs left by earlier runs.
  required final DateTime startedAt,
}) {
  final _paths = <String>[];

  late final UnmodifiableListView<String> paths = UnmodifiableListView(_paths);

  bool get isEmpty => _paths.isEmpty;

  void addAll(Iterable<String> collected) => _paths.addAll(collected);

  final _links = <String, String>{};

  /// Where this run's output can be downloaded, by label. An upload step
  /// records its link here so a later step can pass it on.
  late final UnmodifiableMapView<String, String> links = UnmodifiableMapView(
    _links,
  );

  void addLink(String label, String url) {
    if (label.trim().isEmpty || url.trim().isEmpty) return;
    _links[label.trim()] = url.trim();
  }
}
