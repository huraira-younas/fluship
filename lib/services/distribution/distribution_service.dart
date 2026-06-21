import 'package:fluship/shared/models/distribution/distribution_config.dart';

import 'contracts/distribution_context.dart';
import 'contracts/distribution_handler.dart';
import 'contracts/distribution_logger.dart';
import 'models/pipeline_run_snapshot.dart';
import 'models/distribution_result.dart';
import 'email/report_html_theme.dart';

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

class DistributionService {
  DistributionService({required List<DistributionHandler> handlers})
    : _handlers = List<DistributionHandler>.unmodifiable(handlers);

  final List<DistributionHandler> _handlers;

  Future<void> run({
    required DistributionConfigModel config,
    required PipelineRunSnapshot snapshot,
    required ReportHtmlTheme emailTheme,
    required DistributionLogger logger,
  }) async {
    if (!config.enabled) return;

    final context = DistributionContext(
      emailTheme: emailTheme,
      snapshot: snapshot,
      config: config,
      logger: logger,
    );

    await logger.logLine(
      DistributionResult.success('[distribution started]\n'),
    );

    for (final handler in _handlers) {
      await logger.logLine(
        DistributionResult.success('[${handler.name} started]\n'),
      );
      final result = await handler.run(context);
      await logDistributionHandlerResult(result, logger, handler.name);
    }

    await logger.logLine(
      DistributionResult.success('[distribution finished]\n'),
    );
  }
}
