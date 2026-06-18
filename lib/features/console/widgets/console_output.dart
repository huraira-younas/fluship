import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/console_bloc.dart';

class ConsoleOutput extends StatelessWidget {
  const ConsoleOutput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, List<ConsoleLine>>(
      selector: (state) => state.lines,
      builder: (context, lines) => _ConsoleOutputView(lines: lines),
    );
  }
}

class _ConsoleOutputView extends StatefulWidget {
  const _ConsoleOutputView({required this.lines});

  final List<ConsoleLine> lines;

  @override
  State<_ConsoleOutputView> createState() => _ConsoleOutputViewState();
}

class _ConsoleOutputViewState extends State<_ConsoleOutputView> {
  final _controller = ScrollController();
  int _lastLineCount = 0;
  String _lastTail = '';

  @override
  void didUpdateWidget(covariant _ConsoleOutputView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final count = widget.lines.length;
    final tail = count > 0 ? widget.lines.last.text : '';
    if (count == _lastLineCount && tail == _lastTail) return;

    _lastLineCount = count;
    _lastTail = tail;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final maxExtent = _controller.position.maxScrollExtent;
      if (_controller.offset >= maxExtent - 48) {
        _controller.jumpTo(maxExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _lineColor(ConsoleStream stream, FlushipThemeExtension ft) {
    return switch (stream) {
      .stderr => ft.colors.danger,
      .system => ft.colors.muted,
      .input => ft.colors.accent,
      .stdout => ft.colors.text,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Container(
      decoration: BoxDecoration(
        border: .all(color: ft.colors.consoleBorder),
        borderRadius: .circular(ft.radius.btn),
        color: ft.colors.consoleInner,
      ),
      padding: .all(ft.spacing.md),
      width: .maxFinite,
      child: widget.lines.isEmpty
          ? const AppText.label(
              'Output will appear here. Type a command below and press Enter.',
            )
          : ListView.builder(
              controller: _controller,
              itemCount: widget.lines.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemBuilder: (context, index) {
                final line = widget.lines[index];
                return RepaintBoundary(
                  child: AppText.custom(
                    color: _lineColor(line.stream, ft),
                    selectable: true,
                    softWrap: true,
                    size: .body,
                    line.text,
                  ),
                );
              },
            ),
    );
  }
}
