import 'package:fluship/features/console/models/console_line.dart';

String formatPipelineLogLines(List<ConsoleLine> lines) {
  if (lines.isEmpty) return '';

  final buffer = StringBuffer();
  for (final line in lines) {
    buffer.writeln(line.text);
  }

  return buffer.toString();
}
