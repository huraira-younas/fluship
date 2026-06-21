import 'package:fluship/features/pipeline/contracts/pipeline_console_port.dart';

class DistributionLogger {
  const DistributionLogger({
    required this._consolePort,
    required this._sessionId,
  });

  final PipelineConsolePort _consolePort;
  final String _sessionId;

  Future<void> logLine(String text) {
    return _consolePort.logLine(
      sessionId: _sessionId,
      stream: .system,
      text: text,
    );
  }
}
