import 'package:fluship/features/pipeline/contracts/pipeline_console_port.dart';
import 'contracts/distribution_logger.dart';
import 'models/distribution_result.dart';

class PipelineDistributionLogger implements DistributionLogger {
  const PipelineDistributionLogger({
    required this._consolePort,
    required this._sessionId,
  });

  final PipelineConsolePort _consolePort;
  final String _sessionId;

  @override
  Future<void> logLine(DistributionResult result) {
    return _consolePort.logLine(
      sessionId: _sessionId,
      stream: switch (result.status) {
        .skipped => .system,
        .success => .input,
        .failed => .stderr,
      },
      text: result.message,
    );
  }
}
