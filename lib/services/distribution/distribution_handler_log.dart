import 'contracts/distribution_logger.dart';
import 'models/distribution_result.dart';

String distributionLogLabel(String handlerName) {
  return handlerName.replaceAll(' Upload', '').replaceAll(' Email', '');
}

Future<void> logDistributionHandlerResult(
  DistributionResult result,
  DistributionLogger logger,
  String handlerName,
) {
  final label = distributionLogLabel(handlerName);
  final raw = result.message.trim();
  final message = switch (result.status) {
    .success => raw.isEmpty ? '$label finished' : raw,
    .skipped => '$label skipped: $raw',
    .failed => '$label failed: $raw',
  };

  return logger.logLine(result.copyWith(message: '$message\n'));
}
