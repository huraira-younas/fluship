import '../contracts/exports.dart';
import '../models/exports.dart';

class DriveLinkEmailHandler implements DistributionHandler {
  const DriveLinkEmailHandler();

  @override
  String get name => 'Drive Link Email';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    final drive = context.config.driveConfig;
    if (drive == null || !drive.enabled) {
      return DistributionResult.skipped('Drive link email is disabled.');
    }

    return DistributionResult.skipped(
      'Drive link email is not implemented yet.',
    );
  }
}
