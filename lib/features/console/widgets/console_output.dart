import 'package:fluship/features/console/utils/console_line_classifier.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../bloc/console_bloc.dart';

@immutable
class const ConsoleOutputSnapshot({
  required final int headSignature,
  required final int tailSignature,
  required final int lineCount,
  required final List<ConsoleLine> lines,
  final String? sessionId,
}) extends Equatable {
  factory fromState(ConsoleState state) {
    final lines = state.activeSession?.lines ?? const [];
    return ConsoleOutputSnapshot(
      headSignature: lines.isEmpty
          ? 0
          : Object.hash(lines.first.stream, lines.first.text, lines.first.kind),
      tailSignature: lines.isEmpty
          ? 0
          : Object.hash(lines.last.stream, lines.last.text, lines.last.kind),
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

class const ConsoleOutput({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, ConsoleOutputSnapshot>(
      selector: ConsoleOutputSnapshot.fromState,
      builder: (context, snapshot) {
        return _ConsoleOutputView(
          onClear: () => context.read<ConsoleBloc>().add(const ClearConsole()),
          sessionId: snapshot.sessionId,
          lines: snapshot.lines,
        );
      },
    );
  }
}

class const _ConsoleOutputView({
  required final String? sessionId,
  required final VoidCallback onClear,
  required final List<ConsoleLine> lines,
}) extends StatefulWidget {
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
    final colors = ft.colors;

    return Container(
      clipBehavior: .hardEdge,
      height: .infinity,
      width: .infinity,
      decoration: BoxDecoration(
        border: .all(color: colors.consoleBorder),
        borderRadius: .only(
          bottomLeft: .circular(ft.radius.btn),
          bottomRight: .circular(ft.radius.btn),
        ),
        color: colors.consoleInner,
      ),
      padding: .all(ft.spacing.md),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: <Widget>[
              AppText(
                color: colors.text,
                variant: .custom,
                weight: .w600,
                'Output',
              ),
              const Spacer(),
              GestureDetector(
                behavior: .opaque,
                onTap: widget.onClear,
                child: AppText('Clear', color: colors.muted, variant: .custom),
              ),
            ],
          ),
          SizedBox(height: ft.spacing.sm),
          NotificationListener<UserScrollNotification>(
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
                    color: _lineColor(line.displayKind, ft),
                    line: line,
                  );
                },
              ),
            ),
          ).expanded(),
        ],
      ),
    );
  }
}

Color _lineColor(ConsoleLineKind kind, FlushipThemeExtension ft) {
  return switch (kind) {
    .success => ft.colors.success,
    .progress => ft.colors.accent,
    .error => ft.colors.danger,
    .warn => ft.colors.warn,
    .info => ft.colors.text,
  };
}

class const _ConsoleLineRow({
  required final Color color,
  required final ConsoleLine line,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppText.custom(color: color, softWrap: true, size: .body, line.text);
  }
}
