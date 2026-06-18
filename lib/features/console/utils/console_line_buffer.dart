import 'package:fluship/services/console/console_limits.dart';
import '../models/console_line.dart';

class ConsoleLineBuffer {
  const ConsoleLineBuffer._();

  static List<ConsoleLine> mergeChunk({
    required List<ConsoleLine> lines,
    required ConsoleStream stream,
    required String chunk,
  }) {
    if (chunk.isEmpty) return lines;

    final result = List<ConsoleLine>.from(lines);
    if (result.isNotEmpty && result.last.stream == stream) {
      final merged = limitText(result.last.text + chunk);
      result[result.length - 1] = result.last.copyWith(text: merged);
    } else {
      result.add(ConsoleLine(stream: stream, text: limitText(chunk)));
    }
    return trimLines(result);
  }

  static List<ConsoleLine> appendLine({
    required List<ConsoleLine> lines,
    required ConsoleStream stream,
    required String text,
  }) {
    return trimLines([...lines, ConsoleLine(stream: stream, text: text)]);
  }

  static List<ConsoleLine> trimLines(List<ConsoleLine> lines) {
    if (lines.length <= ConsoleLimits.maxLinesPerSession) return lines;
    return lines.sublist(lines.length - ConsoleLimits.maxLinesPerSession);
  }

  static String limitText(String text) {
    if (text.length <= ConsoleLimits.maxLineLength) return text;
    return '${text.substring(0, ConsoleLimits.maxLineLength)}\n… [output truncated]';
  }
}
