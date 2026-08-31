import 'package:fluship/services/console/console_limits.dart';
import 'console_line_classifier.dart';
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
    final chunkKind = classifyConsoleLine(chunk, stream);
    if (lines.isNotEmpty &&
        lines.last.stream == stream &&
        !lines.last.complete) {
      final last = lines.last;
      lines[lines.length - 1] = last.copyWith(
        kind: upgradeConsoleLineKind(last.kind, chunkKind),
        text: limitText(last.text + chunk),
      );
    } else {
      lines.add(
        ConsoleLine(stream: stream, text: limitText(chunk), kind: chunkKind),
      );
    }
    trimLinesInPlace(lines);
  }

  static List<ConsoleLine> appendLine({
    required List<ConsoleLine> lines,
    required ConsoleStream stream,
    ConsoleLineKind? kind,
    required String text,
  }) {
    return trimLines([
      ...lines,
      ConsoleLine(
        kind: kind ?? classifyConsoleLine(text, stream),
        complete: true,
        stream: stream,
        text: text,
      ),
    ]);
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
