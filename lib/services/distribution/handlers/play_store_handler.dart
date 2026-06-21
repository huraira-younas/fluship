import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';

class PlayStoreHandler implements DistributionHandler {
  const PlayStoreHandler();

  @override
  String get name => 'Play Store Upload';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    if (context.config.playstore == null) {
      return DistributionResult.skipped('Play Store upload is disabled.');
    }

    return DistributionResult.skipped(
      'Play Store distribution is not implemented yet.',
    );
  }
}
