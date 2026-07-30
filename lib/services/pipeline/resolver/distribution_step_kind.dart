import 'pipeline_step_id.dart';

enum DistributionStepKind {
  playStore(
    'Publish the App Bundle to Google Play',
    'Upload to Play Store',
    .distPlay,
  ),
  appStore(
    'Upload the IPA to App Store Connect (TestFlight)',
    'Upload to App Store',
    .distAppStore,
  ),
  drive(
    'Upload build artifacts to Google Drive',
    'Upload to Google Drive',
    .distDrive,
  ),
  report(
    'Email the build report to configured recipients',
    'Send Build Report',
    .report,
  );

  const DistributionStepKind(this.description, this.command, this.id);

  final PipelineStepId id;
  final String description;
  final String command;

  /// Steps that must have produced an artifact for this upload to make sense.
  /// Drive and the report have no edge because they self skip when the run
  /// collected nothing.
  Set<PipelineStepId> get dependsOn => switch (this) {
    .playStore => const {.collectAab},
    .appStore => const {.collectIpa},
    .drive || .report => const {},
  };
}
