import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/console/models/console_line.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class ConsoleOutput extends StatefulWidget {
  const ConsoleOutput({required this.lines, super.key});
  final List<ConsoleLine> lines;

  @override
  State<ConsoleOutput> createState() => _ConsoleOutputState();
}

class _ConsoleOutputState extends State<ConsoleOutput> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(covariant ConsoleOutput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length != oldWidget.lines.length ||
        (widget.lines.isNotEmpty &&
            oldWidget.lines.isNotEmpty &&
            widget.lines.last != oldWidget.lines.last)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    }
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
      child: widget.lines.isEmpty
          ? const AppText.label(
              'Output will appear here. Type a command below and press Enter.',
            )
          : ListView.builder(
              itemCount: widget.lines.length,
              controller: _controller,
              itemBuilder: (context, index) {
                final line = widget.lines[index];
                return AppText.custom(
                  line.text,
                  color: _lineColor(line.stream, ft),
                  selectable: true,
                  softWrap: true,
                  size: .body,
                );
              },
            ),
    );
  }
}
