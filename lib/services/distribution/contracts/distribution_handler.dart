import '../models/distribution_result.dart';
import 'distribution_context.dart';

abstract interface class DistributionHandler {
  String get name;

  Future<DistributionResult> run(DistributionContext context);
}
