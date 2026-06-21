import 'package:fluship/shared/models/distribution/distribution_config.dart';

import 'contracts/distribution_context.dart';
import 'contracts/distribution_handler.dart';
import 'contracts/distribution_logger.dart';
import 'models/distribution_result.dart';
import 'models/pipeline_run_snapshot.dart';

class DistributionService {
  DistributionService({required List<DistributionHandler> handlers})
    : _handlers = List<DistributionHandler>.unmodifiable(handlers);

  final List<DistributionHandler> _handlers;

  Future<void> run({
    required PipelineRunSnapshot snapshot,
    required DistributionConfigModel config,
    required DistributionLogger logger,
  }) async {
    if (!config.enabled) return;

    final context = DistributionContext(
      snapshot: snapshot,
      config: config,
      logger: logger,
    );

    await logger.logLine('[distribution started]\n');

    for (final handler in _handlers) {
      final result = await handler.run(context);
      final prefix = switch (result.status) {
        DistributionResultStatus.success => '[distribution] ${handler.name}:',
        DistributionResultStatus.skipped => '[distribution] ${handler.name} skipped:',
        DistributionResultStatus.failed => '[distribution] ${handler.name} failed:',
      };

      final suffix = result.message.isEmpty ? '\n' : ' ${result.message}\n';
      await logger.logLine('$prefix$suffix');
    }

    await logger.logLine('[distribution finished]\n');
  }
}
