import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/features/pipeline/contracts/pipeline_console_port.dart';

import 'contracts/distribution_logger.dart';

class PipelineDistributionLogger implements DistributionLogger {
  PipelineDistributionLogger({
    required PipelineConsolePort consolePort,
    required String sessionId,
  }) : _consolePort = consolePort,
       _sessionId = sessionId;

  final PipelineConsolePort _consolePort;
  final String _sessionId;

  @override
  Future<void> logLine(String text) {
    return _consolePort.logLine(
      sessionId: _sessionId,
      stream: ConsoleStream.system,
      text: text,
    );
  }
}
