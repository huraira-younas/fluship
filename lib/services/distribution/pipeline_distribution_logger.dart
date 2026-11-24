import 'package:fluship/features/pipeline/contracts/pipeline_console_port.dart';

import 'contracts/distribution_logger.dart';
import 'models/distribution_result.dart';

class const PipelineDistributionLogger({
  required final PipelineConsolePort _consolePort,
  required final String _sessionId,
}) implements DistributionLogger {
  @override
  Future<void> logLine(DistributionResult result) {
    return _consolePort.logLine(
      sessionId: _sessionId,
      stream: switch (result.status) {
        .skipped => .system,
        .success => .stdout,
        .failed => .stderr,
      },
      kind: switch (result.status) {
        .skipped => .info,
        .failed => .error,
        .success => null,
      },
      text: result.message,
    );
  }
}
