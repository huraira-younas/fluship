import '../contracts/shell_output_parser.dart';
import '../models/shell_parse_result.dart';
import 'shell_cwd_normalizer.dart';

class MarkerShellOutputParser implements IShellOutputParser {
  static const _cwdEndMarker = '__FLUSHIP_CWD_END__';
  static const _cwdBeginMarker = '__FLUSHIP_CWD__';
  static const _beginMarker = '__FLUSHIP_BEGIN__';
  static const _endPrefix = '__FLUSHIP_END__:';

  final _buffer = StringBuffer();
  var _inCommand = false;
  var _cancelled = false;
  var _inCwd = false;

  @override
  void reset() {
    _buffer.clear();
    _inCommand = false;
    _cancelled = false;
    _inCwd = false;
  }

  @override
  void markCancelled() => _cancelled = true;

  @override
  ShellParseResult feed(String chunk) {
    if (chunk.isEmpty) return const ShellParseResult();
    _buffer.write(chunk);
    return _drain();
  }

  @override
  ShellParseResult flush() => _drain(finish: true);

  ShellParseResult _drain({bool finish = false}) {
    var content = _buffer.toString();
    _buffer.clear();

    var complete = false;
    var stdout = '';
    int? exitCode;
    String? cwd;

    while (true) {
      if (!_inCommand && !_inCwd) {
        final beginIdx = content.indexOf(_beginMarker);
        if (beginIdx != -1) {
          content = content.substring(beginIdx + _beginMarker.length);
          _inCommand = true;
          continue;
        }

        final cwdIdx = content.indexOf(_cwdBeginMarker);
        if (cwdIdx != -1) {
          var rest = content.substring(cwdIdx + _cwdBeginMarker.length);
          if (rest.startsWith('\r')) rest = rest.substring(1);
          if (rest.startsWith('\n')) rest = rest.substring(1);
          content = rest;
          _inCwd = true;
          continue;
        }

        if (finish) content = '';
        break;
      }

      if (_inCommand) {
        final endIdx = content.indexOf(_endPrefix);
        if (endIdx == -1) {
          final overlap = _partialMarkerOverlap(content, _endPrefix);
          final emitLength = content.length - overlap;
          if (emitLength > 0) {
            stdout += content.substring(0, emitLength);
            content = content.substring(emitLength);
          }
          break;
        }

        stdout += content.substring(0, endIdx);
        var rest = content.substring(endIdx + _endPrefix.length);
        final lineEnd = rest.indexOf('\n');
        final codeStr = lineEnd == -1
            ? rest.trim()
            : rest.substring(0, lineEnd).trim();
        exitCode = int.tryParse(codeStr) ?? 1;
        rest = lineEnd == -1 ? '' : rest.substring(lineEnd + 1);
        _inCommand = false;
        content = rest;
        continue;
      }

      if (_inCwd) {
        final endIdx = content.indexOf(_cwdEndMarker);
        if (endIdx == -1) break;

        cwd = normalizeShellCwd(content.substring(0, endIdx));
        var rest = content.substring(endIdx + _cwdEndMarker.length);
        if (rest.startsWith('\r')) rest = rest.substring(1);
        if (rest.startsWith('\n')) rest = rest.substring(1);
        complete = true;
        content = rest;
        _inCwd = false;
        continue;
      }
    }

    if (content.isNotEmpty) _buffer.write(content);

    if (complete || (_cancelled && finish)) {
      return ShellParseResult(
        stdoutChunk: stdout.isEmpty ? null : stdout,
        exitCode: exitCode ?? (_cancelled ? -1 : 0),
        isCommandComplete: true,
        wasCancelled: _cancelled,
        cwd: cwd,
      );
    }

    return ShellParseResult(
      stdoutChunk: stdout.isEmpty ? null : stdout,
      exitCode: exitCode,
      cwd: cwd,
    );
  }

  int _partialMarkerOverlap(String content, String marker) {
    final max = marker.length < content.length ? marker.length : content.length;
    for (var overlap = max; overlap > 0; overlap--) {
      if (marker.startsWith(content.substring(content.length - overlap))) {
        return overlap;
      }
    }
    return 0;
  }
}
