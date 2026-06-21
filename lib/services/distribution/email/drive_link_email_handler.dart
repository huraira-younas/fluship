import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';

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
