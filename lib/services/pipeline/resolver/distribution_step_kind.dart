import 'pipeline_step_id.dart';

enum DistributionStepKind(
  final String description,
  final String command,
  final PipelineStepId id,
) {
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
  ),
  whatsapp(
    'Send the build summary and log to WhatsApp',
    'Send to WhatsApp',
    .whatsapp,
  );

  /// Notifications go out even when the run aborted, so a failed build is
  /// still reported.
  bool get alwaysRun => switch (this) {
    .report || .whatsapp => true,
    .playStore || .appStore || .drive => false,
  };

  /// Steps that must have produced an artifact for this upload to make sense.
  /// The report has no edge because it has to go out even for a failed run.
  Set<PipelineStepId> get dependsOn => switch (this) {
    .playStore => const {.collectAab},
    .appStore => const {.collectIpa},
    .drive => const {.collectApk},
    .report || .whatsapp => const {},
  };
}
