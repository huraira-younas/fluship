import '../contracts/exports.dart';
import '../models/exports.dart';

class GoogleDriveHandler implements DistributionHandler {
  const GoogleDriveHandler();

  @override
  String get name => 'Google Drive Upload';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    final drive = context.config.driveConfig;
    if (drive == null || !drive.enabled) {
      return DistributionResult.skipped('Google Drive upload is disabled.');
    }

    return DistributionResult.skipped(
      'Google Drive distribution is not implemented yet.',
    );
  }
}
