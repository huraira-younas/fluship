import 'contracts/distribution_logger.dart';
import 'models/distribution_result.dart';

Future<void> logDistributionHandlerResult(
  DistributionResult result,
  DistributionLogger logger,
  String handlerName,
) {
  final prefix = switch (result.status) {
    .skipped => '[distribution] $handlerName skipped:',
    .failed => '[distribution] $handlerName failed:',
    .success => '[distribution] $handlerName:',
  };

  final suffix = result.message.isEmpty ? '\n' : ' ${result.message}\n';
  return logger.logLine(result.copyWith(message: '$prefix$suffix'));
}
