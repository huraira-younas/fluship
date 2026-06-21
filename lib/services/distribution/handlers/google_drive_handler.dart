import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';

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
