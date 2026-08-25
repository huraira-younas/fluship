import 'dart:io';

import '../../host/board_reply.dart';
import '../../progress/progress.dart';
import '../../progress/progress_state.dart';

void main() {
  _boardDetect();
  _runCursor();
  _stopDecisions();
  _toolNudge();
  stdoutOk();
}

void _boardDetect() {
  final board = formatProgressBoard(
    selected: const ['preCommit', 'prePull'],
    done: const ['preCommit'],
    current: 'prePull',
    results: const {'preCommit': 'ok'},
    times: const {'preCommit': '0.3s'},
    appName: 'Reelstay',
    version: '2.0.1',
    buildNumber: '2001',
  );
  _check(replyContainsBoard(board), 'raw board');
  _check(replyContainsBoard('```\n$board\n```'), 'fenced board');
  _check(
    !replyContainsBoard('Printing the board and starting prePull'),
    'talk',
  );
  _check(!replyContainsBoard('FLUSHIP without a frame or now line'), 'partial');
  _check(extractBoard('noise\n$board\nmore').contains('FLUSHIP'), 'extract');
  _check(
    isProgressCommand('dart tool/pipeline_progress.dart --current x'),
    'cmd',
  );
  _check(!isProgressCommand('dart tool/pipeline_cleanup.dart'), 'other cmd');
}

void _runCursor() {
  _check(
    runCursorFor(
          state: const PipelineProgressState(
            selected: ['preCommit', 'prePull'],
            done: ['preCommit'],
            now: 'prePull',
          ),
          iosAllowed: true,
        ).finishId ==
        'prePull',
    'finish current',
  );
  _check(
    runCursorFor(
          state: const PipelineProgressState(
            selected: ['preCommit', 'prePull'],
            done: ['preCommit'],
            results: {'preCommit': 'ok'},
          ),
          iosAllowed: true,
        ).startId ==
        'prePull',
    'start next',
  );
  _check(
    runCursorFor(
      state: const PipelineProgressState(selected: ['buildIpa', 'collectIpa']),
      iosAllowed: false,
    ).cleanup,
    'skip ios',
  );
  _check(
    runCursorFor(
          state: const PipelineProgressState(
            selected: ['pubGet', 'pubUpgrade', 'format'],
            done: ['pubGet'],
            results: {'pubGet': 'ok'},
          ),
          iosAllowed: true,
        ).startId ==
        'format',
    'mutex skips the other',
  );
  _check(
    runCursorFor(
          state: const PipelineProgressState(
            selected: ['buildAab', 'collectAab', 'postCommit'],
            done: ['buildAab'],
            results: {'buildAab': 'fail'},
          ),
          iosAllowed: true,
        ).startId ==
        'postCommit',
    'skip child after parent fail',
  );
  _check(
    runCursorFor(
          state: const PipelineProgressState(
            selected: ['clean', 'format', 'report'],
            done: ['clean'],
            results: {'clean': 'fail'},
          ),
          iosAllowed: true,
        ).startId ==
        'report',
    'critical fail still runs report',
  );
  _check(
    runCursorFor(
      state: const PipelineProgressState(
        selected: ['preCommit'],
        done: ['preCommit'],
        results: {'preCommit': 'ok'},
        now: 'preCommit',
      ),
      iosAllowed: true,
    ).cleanup,
    'cleanup when selected are done',
  );
}

void _stopDecisions() {
  final now = DateTime.utc(2026, 8, 25, 14);
  final board = formatProgressBoard(
    selected: const ['preCommit', 'prePull'],
    done: const ['preCommit'],
    current: 'preCommit',
    appName: 'Reelstay',
    version: '2.0.1',
    buildNumber: '2001',
  );
  const running = PipelineProgressState(
    selected: ['preCommit', 'prePull'],
    done: ['preCommit'],
    results: {'preCommit': 'ok'},
    now: 'preCommit',
  );
  final afterBoard = gateAfterReply(
    existing: gateAfterProgress(
      existing: const BoardGate(),
      board: board,
      now: now,
    ),
    text: board,
    now: now,
  );
  final next = decideStop(
    gate: afterBoard,
    state: running,
    status: 'completed',
    now: now,
    iosAllowed: true,
  );
  _check(next.action == BoardHookAction.startJob, 'board reply continues');
  _check(next.jobId == 'prePull', 'continues with next id');
  _check(next.followup.contains('prePull'), 'followup names the job');

  final missed = decideStop(
    gate: BoardGate(
      progressAt: now,
      board: board,
      lastReplyAt: now,
      lastReplyHasBoard: false,
      lastReplyLength: 40,
      seenThisTurn: true,
    ),
    state: running,
    status: 'completed',
    now: now,
    iosAllowed: true,
  );
  _check(missed.action == BoardHookAction.pasteBoard, 'nudge short miss');
  _check(missed.followup.contains('FLUSHIP'), 'nudge includes board');

  final docs = decideStop(
    gate: BoardGate(
      progressAt: now,
      board: board,
      lastReplyAt: now,
      lastReplyHasBoard: false,
      lastReplyLength: 900,
      seenThisTurn: true,
    ),
    state: running,
    status: 'completed',
    now: now,
    iosAllowed: true,
  );
  _check(docs.action == BoardHookAction.none, 'ignore long non-board reply');

  final otherChat = decideStop(
    gate: afterBoard.copyWith(seenThisTurn: false),
    state: running,
    status: 'completed',
    now: now,
    iosAllowed: true,
  );
  _check(
    otherChat.action == BoardHookAction.none,
    'other chat cannot continue',
  );

  final idle = decideStop(
    gate: afterBoard,
    state: const PipelineProgressState(idle: true, selected: ['preCommit']),
    status: 'completed',
    now: now,
    iosAllowed: true,
  );
  _check(idle.action == BoardHookAction.none, 'idle stops the hook');

  final empty = decideStop(
    gate: afterBoard,
    state: const PipelineProgressState(),
    status: 'completed',
    now: now,
    iosAllowed: true,
  );
  _check(empty.action == BoardHookAction.none, 'no selected means no hook');

  final once = decideStop(
    gate: afterBoard.copyWith(cleanupAsked: true),
    state: const PipelineProgressState(
      selected: ['preCommit'],
      done: ['preCommit'],
      results: {'preCommit': 'ok'},
      now: 'preCommit',
    ),
    status: 'completed',
    now: now,
    iosAllowed: true,
  );
  _check(once.action == BoardHookAction.none, 'cleanup asked only once');

  final kept = gateAfterReply(
    existing: afterBoard,
    text: 'A long docs reply about AGENTS.md and thinking ' * 8,
    now: now.add(const Duration(seconds: 1)),
    ignoreLongNonBoard: true,
  );
  _check(kept.lastReplyHasBoard, 'live run keeps the last board reply');
  _check(!kept.seenThisTurn, 'docs reply is not this pipeline turn');
}

void _toolNudge() {
  final hit = decideAfterTool(
    command: 'dart tool/pipeline_progress.dart --current prePull',
  );
  _check(hit.additionalContext.contains('STOP after this tool'), 'tool nudge');
  _check(
    decideAfterTool(command: 'flutter pub get').additionalContext.isEmpty,
    'ignore other shell',
  );
}

void stdoutOk() {
  stdout.writeln('board reply tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
