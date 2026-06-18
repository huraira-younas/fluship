import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/console_bloc.dart';

class ConsoleInput extends StatelessWidget {
  const ConsoleInput({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, bool>(
      selector: (state) => state.activeSession?.isRunning ?? false,
      builder: (context, isRunning) {
        return _ConsoleInputField(
          disabled: isRunning,
          onSubmit: (command) =>
              context.read<ConsoleBloc>().add(SubmitCommand(command: command)),
        );
      },
    );
  }
}

class _ConsoleInputField extends StatefulWidget {
  const _ConsoleInputField({required this.onSubmit, required this.disabled});

  final ValueChanged<String> onSubmit;
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
        AppButton.primary(
          onPressed: widget.disabled ? null : _submit,
          label: 'Run',
          size: .sm,
        ),
      ],
    );
  }
}
