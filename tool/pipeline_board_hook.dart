import 'dart:convert';
import 'dart:io';

import 'pipeline_picker/host/board_reply.dart';
import 'pipeline_picker/io_helpers.dart';
import 'pipeline_picker/progress/progress_state.dart';

/// Cursor hook entry for the chat board. Thinking and tool stdout are not
/// replies, so this continues a run only after a visible board, or nudges
/// a short pipeline turn that skipped pasting.
Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_help);
    return;
  }

  final event = args.isEmpty ? '' : args.first.trim();
  final flags = parseCliFlags(args);
  final agentDir = flagString(flags, 'agent-dir').isEmpty
      ? pathJoin(workspaceRoot(), '.fluship-agent')
      : flagString(flags, 'agent-dir');
  final gatePath = pathJoin(agentDir, boardGateFileName);
  final progressPath = pathJoin(agentDir, 'progress.json');
  final now =
      DateTime.tryParse(flagString(flags, 'now'))?.toUtc() ??
      DateTime.now().toUtc();
  final iosAllowed = flags.containsKey('ios')
      ? flagBool(flags, 'ios')
      : Platform.isMacOS;

  final raw = await utf8.decoder.bind(stdin).join();
  final payload = _payload(raw);
  final gate = loadBoardGate(gatePath);
  final state = loadProgressState(progressPath);

  switch (event) {
    case 'after-shell':
    case 'after-tool':
      final command = toolCommandOf(payload);
      if (event == 'after-tool') {
        _write(decideAfterTool(command: command).toHookJson());
        return;
      }
      if (!isProgressCommand(command)) {
        _write(<String, dynamic>{});
        return;
      }
      final fromOut = extractBoard(toolOutputText(payload));
      final board = fromOut.isEmpty ? boardFromState(state) : fromOut;
      saveBoardGate(
        gatePath,
        gateAfterProgress(existing: gate, board: board, now: now),
      );
      _write(<String, dynamic>{});
      return;
    case 'after-response':
      saveBoardGate(
        gatePath,
        gateAfterReply(
          existing: gate,
          text: asString(payload['text']),
          now: now,
          ignoreLongNonBoard: !state.idle && state.selected.isNotEmpty,
        ),
      );
      _write(<String, dynamic>{});
      return;
    case 'stop':
      final decision = decideStop(
        gate: gate,
        state: state,
        status: asString(payload['status'], 'completed'),
        now: now,
        iosAllowed: iosAllowed,
      );
      saveBoardGate(gatePath, decision.gate);
      _write(decision.toHookJson());
      return;
    default:
      _write(<String, dynamic>{});
  }
}

void _write(Map<String, dynamic> json) {
  stdout.writeln(const JsonEncoder().convert(json));
}

Map<String, dynamic> _payload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } catch (_) {}
  return <String, dynamic>{};
}

const _help = '''
Cursor hook for the Fluship chat board.

Usage:
  dart tool/pipeline_board_hook.dart after-shell
  dart tool/pipeline_board_hook.dart after-tool
  dart tool/pipeline_board_hook.dart after-response
  dart tool/pipeline_board_hook.dart stop
''';
