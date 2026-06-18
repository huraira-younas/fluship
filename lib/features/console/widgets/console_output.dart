import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../bloc/console_bloc.dart';

@immutable
class ConsoleOutputSnapshot extends Equatable {
  const ConsoleOutputSnapshot({
    required this.headSignature,
    required this.tailSignature,
    required this.lineCount,
    required this.lines,
    this.sessionId,
  });

  final List<ConsoleLine> lines;
  final int headSignature;
  final int tailSignature;
  final String? sessionId;
  final int lineCount;

  factory ConsoleOutputSnapshot.fromState(ConsoleState state) {
    final lines = state.activeSession?.lines ?? const [];
    return ConsoleOutputSnapshot(
      headSignature: lines.isEmpty
          ? 0
          : Object.hash(lines.first.stream, lines.first.text),
      tailSignature: lines.isEmpty
          ? 0
          : Object.hash(lines.last.stream, lines.last.text),
      sessionId: state.activeSessionId,
      lineCount: lines.length,
      lines: lines,
    );
  }

  @override
  List<Object?> get props => [
    headSignature,
    tailSignature,
    sessionId,
    lineCount,
  ];
}

class ConsoleOutput extends StatelessWidget {
  const ConsoleOutput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, ConsoleOutputSnapshot>(
      selector: ConsoleOutputSnapshot.fromState,
      builder: (_, snapshot) {
        return _ConsoleOutputView(
          sessionId: snapshot.sessionId,
          lines: snapshot.lines,
        );
      },
    );
  }
}

class _ConsoleOutputView extends StatefulWidget {
  const _ConsoleOutputView({required this.lines, required this.sessionId});

  final List<ConsoleLine> lines;
  final String? sessionId;

  @override
  State<_ConsoleOutputView> createState() => _ConsoleOutputViewState();
}

class _ConsoleOutputViewState extends State<_ConsoleOutputView> {
  static const _stickThreshold = 48.0;

  final _controller = ScrollController();
  var _scrollScheduled = false;
  var _stickToBottom = true;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    _scheduleScrollToBottom(force: true);
  }

  @override
  void didUpdateWidget(covariant _ConsoleOutputView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.sessionId != _sessionId) {
      _sessionId = widget.sessionId;
      _stickToBottom = true;
      _scheduleScrollToBottom(force: true);
      return;
    }

    if (identical(oldWidget.lines, widget.lines)) return;
    _scheduleScrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onUserScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    _stickToBottom = position.pixels <= _stickThreshold;
  }

  void _scheduleScrollToBottom({bool force = false}) {
    if (!force && !_stickToBottom) return;
    if (_scrollScheduled) return;
    _scrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      _scrollToBottom(force);
    });
  }

  void _scrollToBottom(bool force) {
    if (!mounted || !_controller.hasClients) return;
    if (!force && !_stickToBottom) return;

    final position = _controller.position;
    if (!position.hasContentDimensions) {
      _scheduleScrollToBottom(force: force);
      return;
    }

    final target = position.minScrollExtent;
    if (position.pixels > target + 1) {
      _controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final lines = widget.lines;

    return Container(
      clipBehavior: .hardEdge,
      decoration: BoxDecoration(
        border: .all(color: ft.colors.consoleBorder),
        borderRadius: .circular(ft.radius.btn),
        color: ft.colors.consoleInner,
      ),
      padding: .all(ft.spacing.md),
      width: double.maxFinite,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (_) {
          _onUserScroll();
          return false;
        },
        child: SelectionArea(
          child: ListView.builder(
            controller: _controller,
            addAutomaticKeepAlives: false,
            physics: const ClampingScrollPhysics(),
            reverse: true,
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final dataIndex = lines.length - 1 - index;
              final line = lines[dataIndex];
              final isTail = index == 0;
              return _ConsoleLineRow(
                key: isTail
                    ? const ValueKey('console-tail')
                    : ValueKey(dataIndex),
                color: _lineColor(line.stream, ft),
                line: line,
              );
            },
          ),
        ),
      ),
    );
  }
}

Color _lineColor(ConsoleStream stream, FlushipThemeExtension ft) {
  return switch (stream) {
    .stderr => ft.colors.danger,
    .system => ft.colors.muted,
    .input => ft.colors.accent,
    .stdout => ft.colors.text,
  };
}

class _ConsoleLineRow extends StatelessWidget {
  const _ConsoleLineRow({required this.color, required this.line, super.key});

  final ConsoleLine line;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppText.custom(color: color, softWrap: true, size: .body, line.text);
  }
}
