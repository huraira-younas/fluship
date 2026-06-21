enum DistributionStepKind {
  playStore('Upload to Play Store', 'upload: playstore'),
  appStore('Upload to App Store', 'upload: appstore'),
  drive('Upload to Google Drive', 'upload: drive'),
  report('Send Build Report', 'email: report');

  const DistributionStepKind(this.label, this.command);

  final String command;
  final String label;
}
