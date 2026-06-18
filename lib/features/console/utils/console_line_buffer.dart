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
    _mergeInto(result, stream: stream, chunk: chunk);
    return result;
  }

  static void mergeChunkInPlace({
    required List<ConsoleLine> lines,
    required ConsoleStream stream,
    required String chunk,
  }) {
    if (chunk.isEmpty) return;
    _mergeInto(lines, stream: stream, chunk: chunk);
  }

  static void _mergeInto(
    List<ConsoleLine> lines, {
    required ConsoleStream stream,
    required String chunk,
  }) {
    if (lines.isNotEmpty && lines.last.stream == stream) {
      final merged = limitText(lines.last.text + chunk);
      lines[lines.length - 1] = lines.last.copyWith(text: merged);
    } else {
      lines.add(ConsoleLine(stream: stream, text: limitText(chunk)));
    }
    trimLinesInPlace(lines);
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

  static void trimLinesInPlace(List<ConsoleLine> lines) {
    final excess = lines.length - ConsoleLimits.maxLinesPerSession;
    if (excess <= 0) return;
    lines.removeRange(0, excess);
  }

  static String limitText(String text) {
    if (text.length <= ConsoleLimits.maxLineLength) return text;
    return '${text.substring(0, ConsoleLimits.maxLineLength)}\n… [output truncated]';
  }
}
