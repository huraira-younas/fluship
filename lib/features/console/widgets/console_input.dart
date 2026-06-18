import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class ConsoleInput extends StatefulWidget {
  const ConsoleInput({
    required this.onSubmit,
    required this.disabled,
    super.key,
  });

  final ValueChanged<String> onSubmit;
  final bool disabled;

  @override
  State<ConsoleInput> createState() => _ConsoleInputState();
}

class _ConsoleInputState extends State<ConsoleInput> {
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
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: ft.spacing.sm,
      children: [
        const AppText.code('>'),
        Expanded(
          child: TextField(
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
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ft.radius.btn),
                borderSide: BorderSide(color: ft.colors.consoleBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ft.radius.btn),
                borderSide: BorderSide(color: ft.colors.consoleBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ft.radius.btn),
                borderSide: BorderSide(color: ft.colors.accent),
              ),
              filled: true,
              fillColor: ft.colors.consoleInner,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        AppButton.primary(
          onPressed: widget.disabled ? null : _submit,
          label: 'Run',
          size: .sm,
        ),
      ],
    );
  }
}
