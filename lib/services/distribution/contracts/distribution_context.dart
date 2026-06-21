import 'package:fluship/shared/models/distribution/distribution_config.dart';

import '../models/pipeline_run_snapshot.dart';
import '../pipeline_distribution_logger.dart';
import '../email/report_html_theme.dart';

class DistributionContext {
  const DistributionContext({
    required this.emailTheme,
    required this.snapshot,
    required this.config,
    required this.logger,
  });

  final DistributionConfigModel config;
  final PipelineRunSnapshot snapshot;
  final ReportHtmlTheme emailTheme;
  final DistributionLogger logger;
}
