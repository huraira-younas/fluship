import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/console_bloc.dart';

typedef ConsoleInputState = ({bool isPipeline, bool isRunning});

class ConsoleInput extends StatelessWidget {
  const ConsoleInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, ConsoleInputState>(
      selector: (state) {
        return (
          isPipeline: isPipelineConsoleSession(state.activeSessionId ?? ''),
          isRunning: state.activeSession?.isRunning ?? false,
        );
      },
      builder: (context, state) {
        final bloc = context.read<ConsoleBloc>();
        if (state.isPipeline) return const SizedBox.shrink();

        return _ConsoleInputField(
          onSubmit: (cmd) => bloc.add(SubmitCommand(command: cmd)),
          onCancel: () => bloc.add(const CancelCommand()),
          disabled: state.isRunning,
        );
      },
    );
  }
}

class _ConsoleInputField extends StatefulWidget {
  const _ConsoleInputField({
    required this.onSubmit,
    required this.onCancel,
    required this.disabled,
  });

  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final bool disabled;

  @override
  State<_ConsoleInputField> createState() => _ConsoleInputFieldState();
}

class _ConsoleInputFieldState extends State<_ConsoleInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.disabled) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  void _restoreFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.disabled) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant _ConsoleInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.disabled != widget.disabled) {
      if (!widget.disabled) {
        _restoreFocus();
      } else {
        _focusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Row(
      crossAxisAlignment: .center,
      spacing: ft.spacing.sm,
      children: [
        TextField(
          enabled: !widget.disabled,
          controller: _controller,
          focusNode: _focusNode,
          style: TextStyle(
            fontFamily: 'monospace',
            color: ft.colors.text,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: widget.disabled
                ? 'Running...'
                : 'flutter pub get, git status, ...',
            hintStyle: TextStyle(color: ft.colors.muted, fontSize: 14),
            contentPadding: .symmetric(
              horizontal: ft.spacing.md,
              vertical: ft.spacing.md,
            ),
            prefixIcon: Icon(Icons.code, size: 16, color: ft.colors.muted),
            isDense: true,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: ft.colors.consoleBorder),
              borderRadius: .circular(ft.radius.btn),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ft.colors.consoleBorder),
              borderRadius: .circular(ft.radius.btn),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ft.colors.accent),
              borderRadius: .circular(ft.radius.btn),
            ),
            fillColor: ft.colors.consoleInner,
            filled: true,
          ),
          onSubmitted: (_) => _submit(),
        ).expanded(),
        if (widget.disabled)
          AppButton.danger(onPressed: widget.onCancel, label: 'Stop', size: .sm)
        else
          AppButton.primary(onPressed: _submit, label: 'Run', size: .sm),
      ],
    );
  }
}
