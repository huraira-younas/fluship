import 'package:fluship/shared/models/distribution/distribution_config.dart';

import '../upload/pipeline_upload_progress.dart';
import '../models/pipeline_run_snapshot.dart';
import '../email/report_html_theme.dart';
import '../upload/counted_upload.dart';
import 'distribution_logger.dart';

class DistributionContext {
  const DistributionContext({
    required this.emailTheme,
    required this.snapshot,
    this.onUploadProgress,
    this.onLinkPublished,
    required this.config,
    required this.logger,
  });

  final void Function(PipelineUploadProgress progress)? onUploadProgress;
  final void Function(String label, String url)? onLinkPublished;
  final DistributionConfigModel config;
  final PipelineRunSnapshot snapshot;
  final ReportHtmlTheme emailTheme;
  final DistributionLogger logger;

  /// Records a download link for steps that run later in the same pipeline.
  void publishLink(String label, String url) =>
      onLinkPublished?.call(label, url);

  void notifyUploadProgress({
    required UploadChannel channel,
    required String fileName,
    int? fileIndex,
    int? fileCount,
    int? percent,
    int bytes = 0,
    int total = 0,
  }) {
    onUploadProgress?.call(
      PipelineUploadProgress(
        percent: percent ?? uploadPercent(bytes, total),
        fileIndex: fileIndex,
        fileCount: fileCount,
        fileName: fileName,
        channel: channel,
        bytes: bytes,
        total: total,
      ),
    );
  }
}
