import 'dart:convert';

import '../catalog/catalog.dart';
import '../io_helpers.dart';
import '../progress/progress.dart';
import '../progress/progress_state.dart';

const boardGateFileName = 'board-gate.json';
const maxPasteNudges = 3;
const maxShortReplyChars = 280;
const replyFreshSeconds = 12;

class BoardGate {
  const BoardGate({
    this.progressAt,
    this.board = '',
    this.lastReplyAt,
    this.lastReplyHasBoard = false,
    this.lastReplyLength = 0,
    this.lastBoardReplyAt,
    this.pasteNudges = 0,
    this.cleanupAsked = false,
    this.seenThisTurn = false,
  });

  final DateTime? progressAt;
  final String board;
  final DateTime? lastReplyAt;
  final bool lastReplyHasBoard;
  final int lastReplyLength;
  final DateTime? lastBoardReplyAt;
  final int pasteNudges;
  final bool cleanupAsked;
  final bool seenThisTurn;

  BoardGate copyWith({
    DateTime? progressAt,
    String? board,
    DateTime? lastReplyAt,
    bool? lastReplyHasBoard,
    int? lastReplyLength,
    DateTime? lastBoardReplyAt,
    int? pasteNudges,
    bool? cleanupAsked,
    bool? seenThisTurn,
  }) {
    return BoardGate(
      progressAt: progressAt ?? this.progressAt,
      board: board ?? this.board,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      lastReplyHasBoard: lastReplyHasBoard ?? this.lastReplyHasBoard,
      lastReplyLength: lastReplyLength ?? this.lastReplyLength,
      lastBoardReplyAt: lastBoardReplyAt ?? this.lastBoardReplyAt,
      pasteNudges: pasteNudges ?? this.pasteNudges,
      cleanupAsked: cleanupAsked ?? this.cleanupAsked,
      seenThisTurn: seenThisTurn ?? this.seenThisTurn,
    );
  }

  Map<String, dynamic> toJson() => {
    if (progressAt != null) 'progressAt': progressAt!.toUtc().toIso8601String(),
    'board': board,
    if (lastReplyAt != null)
      'lastReplyAt': lastReplyAt!.toUtc().toIso8601String(),
    'lastReplyHasBoard': lastReplyHasBoard,
    'lastReplyLength': lastReplyLength,
    if (lastBoardReplyAt != null)
      'lastBoardReplyAt': lastBoardReplyAt!.toUtc().toIso8601String(),
    'pasteNudges': pasteNudges,
    'cleanupAsked': cleanupAsked,
    'seenThisTurn': seenThisTurn,
  };

  factory BoardGate.fromJson(Map<String, dynamic> json) {
    return BoardGate(
      progressAt: DateTime.tryParse(asString(json['progressAt']))?.toUtc(),
      board: asString(json['board']),
      lastReplyAt: DateTime.tryParse(asString(json['lastReplyAt']))?.toUtc(),
      lastReplyHasBoard: json['lastReplyHasBoard'] == true,
      lastReplyLength: asInt(json['lastReplyLength']) ?? 0,
      lastBoardReplyAt: DateTime.tryParse(
        asString(json['lastBoardReplyAt']),
      )?.toUtc(),
      pasteNudges: asInt(json['pasteNudges']) ?? 0,
      cleanupAsked: json['cleanupAsked'] == true,
      seenThisTurn: json['seenThisTurn'] == true,
    );
  }
}

enum BoardHookAction { none, pasteBoard, finishJob, startJob, cleanup }

class BoardHookDecision {
  const BoardHookDecision({
    required this.action,
    this.jobId = '',
    this.board = '',
    this.followup = '',
    this.additionalContext = '',
    this.gate = const BoardGate(),
  });

  final BoardHookAction action;
  final String jobId;
  final String board;
  final String followup;
  final String additionalContext;
  final BoardGate gate;

  Map<String, dynamic> toHookJson() {
    if (additionalContext.isNotEmpty) {
      return {'additional_context': additionalContext};
    }
    if (followup.isEmpty) return <String, dynamic>{};
    return {'followup_message': followup};
  }
}

class RunCursor {
  const RunCursor({
    this.finishId = '',
    this.startId = '',
    this.cleanup = false,
  });

  final String finishId;
  final String startId;
  final bool cleanup;
}

bool replyContainsBoard(String text) {
  final body = text.trim();
  if (body.isEmpty) return false;
  return body.contains('FLUSHIP') &&
      body.contains('\u250c') &&
      body.contains('now:');
}

String extractBoard(String text) {
  final start = text.indexOf('\u250c');
  final end = text.lastIndexOf('\u2514');
  if (start < 0 || end < start) return '';
  final close = text.indexOf('\n', end);
  return text.substring(start, close < 0 ? text.length : close).trim();
}

bool isProgressCommand(String command) {
  return command.contains('pipeline_progress.dart');
}

String progressNudgeContext() {
  return 'STOP after this tool. pipeline_progress stdout is not a chat reply. '
      'Your entire user-visible reply must be that board in a fenced code '
      'block. Then stop. Do not think. Do not start another job.';
}

RunCursor runCursorFor({
  required PipelineProgressState state,
  required bool iosAllowed,
}) {
  final selected = _inCatalogOrder(state.selected);
  final done = state.done.toSet();
  final current = normalizeStepId(state.now);
  if (current.isNotEmpty && !done.contains(current)) {
    return RunCursor(finishId: current);
  }

  final abort = Catalog.criticalIds.any((id) => state.results[id] == 'fail');
  for (final id in selected) {
    if (done.contains(id)) continue;
    if (!iosAllowed && Catalog.iosIds.contains(id)) continue;
    if (_mutexLoser(id, selected)) continue;
    if (abort && !Catalog.alwaysRunIds.contains(id)) continue;
    if (_parentBlocked(id, state.results)) continue;
    return RunCursor(startId: id);
  }
  return const RunCursor(cleanup: true);
}

BoardGate gateAfterProgress({
  required BoardGate existing,
  required String board,
  required DateTime now,
}) {
  return existing.copyWith(
    progressAt: now.toUtc(),
    board: board,
    pasteNudges: 0,
  );
}

BoardGate gateAfterReply({
  required BoardGate existing,
  required String text,
  required DateTime now,
  bool ignoreLongNonBoard = false,
}) {
  final hasBoard = replyContainsBoard(text);
  final trimmed = text.trim();
  if (ignoreLongNonBoard && !hasBoard && trimmed.length > maxShortReplyChars) {
    return existing.copyWith(seenThisTurn: false);
  }
  return existing.copyWith(
    lastReplyAt: now.toUtc(),
    lastReplyHasBoard: hasBoard,
    lastReplyLength: trimmed.length,
    lastBoardReplyAt: hasBoard ? now.toUtc() : existing.lastBoardReplyAt,
    pasteNudges: hasBoard ? 0 : existing.pasteNudges,
    seenThisTurn: hasBoard || trimmed.length <= maxShortReplyChars,
  );
}

BoardHookDecision decideStop({
  required BoardGate gate,
  required PipelineProgressState state,
  required String status,
  required DateTime now,
  required bool iosAllowed,
}) {
  if (status != 'completed' ||
      state.idle ||
      state.selected.isEmpty ||
      !gate.seenThisTurn) {
    return BoardHookDecision(
      action: BoardHookAction.none,
      gate: _closeTurn(gate),
    );
  }

  final utc = now.toUtc();
  final replyAge = _ageSeconds(gate.lastReplyAt, utc);
  final freshReply = replyAge != null && replyAge <= replyFreshSeconds;

  if (gate.lastReplyHasBoard && freshReply) {
    final cursor = runCursorFor(state: state, iosAllowed: iosAllowed);
    if (cursor.finishId.isNotEmpty) {
      return BoardHookDecision(
        action: BoardHookAction.finishJob,
        jobId: cursor.finishId,
        followup: _finishFollowup(cursor.finishId),
        gate: _closeTurn(gate),
      );
    }
    if (cursor.startId.isNotEmpty) {
      return BoardHookDecision(
        action: BoardHookAction.startJob,
        jobId: cursor.startId,
        followup: _startFollowup(cursor.startId),
        gate: _closeTurn(gate),
      );
    }
    if (gate.cleanupAsked) {
      return BoardHookDecision(
        action: BoardHookAction.none,
        gate: _closeTurn(gate),
      );
    }
    return BoardHookDecision(
      action: BoardHookAction.cleanup,
      followup: _cleanupFollowup,
      gate: _closeTurn(gate).copyWith(cleanupAsked: true),
    );
  }

  final board = gate.board.trim().isEmpty
      ? boardFromState(state)
      : gate.board.trim();
  final progressAge = _ageSeconds(gate.progressAt, utc);
  final unseenBoard =
      gate.progressAt != null &&
      (gate.lastBoardReplyAt == null ||
          gate.progressAt!.isAfter(gate.lastBoardReplyAt!));
  final shortReply = gate.lastReplyLength <= maxShortReplyChars;
  if (freshReply &&
      shortReply &&
      unseenBoard &&
      progressAge != null &&
      !gate.lastReplyHasBoard &&
      gate.pasteNudges < maxPasteNudges &&
      board.isNotEmpty) {
    return BoardHookDecision(
      action: BoardHookAction.pasteBoard,
      board: board,
      followup: _pasteFollowup(board),
      gate: _closeTurn(gate).copyWith(pasteNudges: gate.pasteNudges + 1),
    );
  }

  return BoardHookDecision(
    action: BoardHookAction.none,
    gate: _closeTurn(gate),
  );
}

BoardHookDecision decideAfterTool({required String command}) {
  if (!isProgressCommand(command)) {
    return const BoardHookDecision(action: BoardHookAction.none);
  }
  return BoardHookDecision(
    action: BoardHookAction.pasteBoard,
    additionalContext: progressNudgeContext(),
  );
}

BoardGate loadBoardGate(String path) {
  return BoardGate.fromJson(readJsonFile(path));
}

void saveBoardGate(String path, BoardGate gate) {
  writeJsonFile(path, gate.toJson());
}

void clearBoardGate(String path) {
  deleteIfExists(path);
}

String toolCommandOf(Map<String, dynamic> payload) {
  final direct = asString(payload['command']);
  if (direct.isNotEmpty) return direct;
  final input = payload['tool_input'];
  if (input is Map) {
    return asString(input['command']);
  }
  if (input is String && looksLikeJsonObject(input)) {
    return asString(_jsonMap(input)['command']);
  }
  return '';
}

String toolOutputText(Map<String, dynamic> payload) {
  final output = payload['output'];
  if (output is String && output.trim().isNotEmpty) return output;
  final toolOutput = payload['tool_output'];
  if (toolOutput is String && looksLikeJsonObject(toolOutput)) {
    final stdout = asString(_jsonMap(toolOutput)['stdout']);
    if (stdout.isNotEmpty) return stdout;
  }
  if (toolOutput is Map) {
    return asString(toolOutput['stdout']);
  }
  return '';
}

List<String> _inCatalogOrder(List<String> selected) {
  final wanted = {for (final id in selected) normalizeStepId(id)};
  return [
    for (final step in Catalog.steps)
      if (wanted.contains(step.id)) step.id,
  ];
}

bool _mutexLoser(String id, List<String> selected) {
  for (final group in Catalog.mutexGroups) {
    if (!group.contains(id)) continue;
    final hits = [
      for (final item in group)
        if (selected.contains(item)) item,
    ];
    if (hits.length < 2) return false;
    return hits.first != id;
  }
  return false;
}

bool _parentBlocked(String id, Map<String, String> results) {
  final req = Catalog.parentRequirements[id];
  if (req == null) return false;
  bool ok(String parent) => results[parent] == 'ok';
  if (req.requireAll) return !req.ids.every(ok);
  return !req.ids.any(ok);
}

BoardGate _closeTurn(BoardGate gate) => gate.copyWith(seenThisTurn: false);

int? _ageSeconds(DateTime? from, DateTime now) {
  if (from == null) return null;
  return now.difference(from).inSeconds;
}

String _pasteFollowup(String board) {
  return 'PRINT THE BOARD. Your entire reply is this fenced block. '
      'No tools. No thinking. Then stop.\n\n```\n$board\n```';
}

String _finishFollowup(String id) {
  return 'Continue the Fluship run. Do not think. Poll `$id` in 5s checks '
      'until exit_code. Then run pipeline_progress.dart. Paste that stdout '
      'as your entire reply in a fenced code block. Then STOP. '
      'Do not start another job.';
}

String _startFollowup(String id) {
  return 'Continue the Fluship run. Do not think. Start only `$id`. '
      'Then run pipeline_progress.dart. Paste that stdout as your entire '
      'reply in a fenced code block. Then STOP. Do not start another job.';
}

const _cleanupFollowup =
    'Selected jobs are done. Run cleanup, then paste the final board as '
    'your entire reply. Then summarize. Do not think.';

Map<String, dynamic> _jsonMap(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } catch (_) {}
  return <String, dynamic>{};
}
