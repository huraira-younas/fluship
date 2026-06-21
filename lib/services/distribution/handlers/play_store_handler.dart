import '../contracts/exports.dart';
import '../models/exports.dart';

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
