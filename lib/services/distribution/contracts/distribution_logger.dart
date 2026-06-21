import '../models/distribution_result.dart';

abstract interface class DistributionLogger {
  Future<void> logLine(DistributionResult result);
}
