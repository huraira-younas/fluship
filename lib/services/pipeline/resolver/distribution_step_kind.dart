enum DistributionStepKind {
  playStore('Publish the App Bundle to Google Play', 'Upload to Play Store'),
  appStore(
    'Upload the IPA to App Store Connect (TestFlight)',
    'Upload to App Store',
  ),
  drive('Upload build artifacts to Google Drive', 'Upload to Google Drive'),
  report(
    'Email the build report to configured recipients',
    'Send Build Report',
  );

  const DistributionStepKind(this.description, this.command);

  final String description;
  final String command;
}
