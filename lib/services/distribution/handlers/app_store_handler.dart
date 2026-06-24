import '../contracts/exports.dart';
import '../models/exports.dart';

class AppStoreHandler implements DistributionHandler {
  const AppStoreHandler();

  @override
  String get name => 'App Store Upload';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    if (context.config.appstore == null) {
      return DistributionResult.skipped('App Store upload is disabled.');
    }

    return DistributionResult.skipped(
      'App Store distribution is not implemented yet.',
    );
  }
}
