import '../contracts/shell_output_parser.dart';
import '../models/shell_parse_result.dart';

class MarkerShellOutputParser implements IShellOutputParser {
  MarkerShellOutputParser({
    this.cwdEndMarker = '__FLUSHIP_CWD_END__',
    this.cwdBeginMarker = '__FLUSHIP_CWD__',
    this.beginMarker = '__FLUSHIP_BEGIN__',
    this.endPrefix = '__FLUSHIP_END__:',
  });

  final String cwdBeginMarker;
  final String cwdEndMarker;
  final String beginMarker;
  final String endPrefix;

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
    var stdout = '';
    int? exitCode;
    String? cwd;
    var complete = false;

    while (true) {
      final content = _buffer.toString();
      if (!_inCommand && !_inCwd) {
        final beginIdx = content.indexOf(beginMarker);
        if (beginIdx != -1) {
          _buffer
            ..clear()
            ..write(content.substring(beginIdx + beginMarker.length));
          _inCommand = true;
          continue;
        }

        final cwdIdx = content.indexOf(cwdBeginMarker);
        if (cwdIdx != -1) {
          var rest = content.substring(cwdIdx + cwdBeginMarker.length);
          if (rest.startsWith('\r')) rest = rest.substring(1);
          if (rest.startsWith('\n')) rest = rest.substring(1);
          _buffer
            ..clear()
            ..write(rest);
          _inCwd = true;
          continue;
        }

        if (finish) _buffer.clear();
        break;
      }

      if (_inCommand) {
        final endIdx = content.indexOf(endPrefix);
        if (endIdx == -1) {
          break;
        }

        stdout += content.substring(0, endIdx);
        var rest = content.substring(endIdx + endPrefix.length);
        final lineEnd = rest.indexOf('\n');
        final codeStr = lineEnd == -1
            ? rest.trim()
            : rest.substring(0, lineEnd).trim();
        exitCode = int.tryParse(codeStr) ?? 1;
        rest = lineEnd == -1 ? '' : rest.substring(lineEnd + 1);
        _buffer
          ..clear()
          ..write(rest);
        _inCommand = false;
        continue;
      }

      if (_inCwd) {
        final endIdx = content.indexOf(cwdEndMarker);
        if (endIdx == -1) break;

        cwd = content.substring(0, endIdx).trim();
        var rest = content.substring(endIdx + cwdEndMarker.length);
        if (rest.startsWith('\r')) rest = rest.substring(1);
        if (rest.startsWith('\n')) rest = rest.substring(1);
        _buffer
          ..clear()
          ..write(rest);
        _inCwd = false;
        complete = true;
        continue;
      }
    }

    if (complete || (_cancelled && finish)) {
      return ShellParseResult(
        stdoutChunk: stdout.isEmpty ? null : stdout,
        isCommandComplete: true,
        wasCancelled: _cancelled,
        exitCode: exitCode ?? (_cancelled ? -1 : 0),
        cwd: cwd,
      );
    }

    return ShellParseResult(
      stdoutChunk: stdout.isEmpty ? null : stdout,
      exitCode: exitCode,
      cwd: cwd,
    );
  }
}
