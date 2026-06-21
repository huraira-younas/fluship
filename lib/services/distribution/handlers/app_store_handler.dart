import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';

class AppStoreHandler implements DistributionHandler {
  const AppStoreHandler();

  @override
  String get name => 'App Store Upload';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    if (!context.config.appstore) {
      return DistributionResult.skipped('App Store upload is disabled.');
    }

    return DistributionResult.skipped(
      'App Store distribution is not implemented yet.',
    );
  }
}
