import 'package:fluship/shared/models/distribution/distribution_config.dart';

import '../models/pipeline_run_snapshot.dart';
import 'distribution_logger.dart';

class DistributionContext {
  DistributionContext({
    required this.snapshot,
    required this.config,
    required this.logger,
  });

  final PipelineRunSnapshot snapshot;
  final DistributionConfigModel config;
  final DistributionLogger logger;

  final Map<String, Object?> shared = {};
}
