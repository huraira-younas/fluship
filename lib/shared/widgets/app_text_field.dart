import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

enum AppTextFieldVariant { floatingLabel, label, custom }

@immutable
class _AppTextFieldDecoration {
  const _AppTextFieldDecoration._();

  static TextStyle textStyle(ThemePalette colors) =>
      TextStyle(fontWeight: .w400, color: colors.text, fontSize: 14);

  static TextStyle hintStyle(ThemePalette colors) =>
      TextStyle(color: colors.muted, fontWeight: .w400, fontSize: 14);

  static EdgeInsets contentPadding(ThemeSpacing spacing) =>
      .symmetric(horizontal: spacing.md, vertical: spacing.md);

  static InputDecoration floatingLabel({
    required FlushipThemeExtension theme,
    required String label,
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    final colors = theme.colors;

    return InputDecoration(
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        final focused = states.contains(WidgetState.focused);
        return TextStyle(
          color: focused ? colors.accent : colors.section,
          backgroundColor: theme.codeBg,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        );
      }),
      labelStyle: WidgetStateTextStyle.resolveWith((states) {
        final focused = states.contains(WidgetState.focused);
        return TextStyle(
          color: focused ? colors.accent : colors.muted,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        );
      }),
      contentPadding: contentPadding(theme.spacing),
      floatingLabelBehavior: .auto,
      hintStyle: hintStyle(colors),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      labelText: label,
      hintText: hint,
    );
  }

  static InputDecoration hintOnly({
    required FlushipThemeExtension theme,
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      contentPadding: contentPadding(theme.spacing),
      hintStyle: hintStyle(theme.colors),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      hintText: hint,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField.floatingLabel({
    this.obscureText = false,
    this.autofocus = false,
    this.autovalidateMode,
    this.readOnly = false,
    this.textInputAction,
    this.enabled = true,
    required this.label,
    required this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.keyboardType,
    this.onSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.controller,
    this.onChanged,
    this.validator,
    this.formKey,
    super.key,
  }) : variant = .floatingLabel,
       decoration = null,
       assert(
         controller == null || initialValue == null,
         'Use either controller or initialValue, not both.',
       );

  const AppTextField.label({
    this.obscureText = false,
    this.autofocus = false,
    this.readOnly = false,
    this.autovalidateMode,
    this.textInputAction,
    this.enabled = true,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.controller,
    this.onChanged,
    this.validator,
    this.formKey,
    this.initialValue,
    super.key,
  }) : decoration = null,
       variant = .label,
       assert(
         controller == null || initialValue == null,
         'Use either controller or initialValue, not both.',
       );

  const AppTextField.custom({
    required this.decoration,
    this.obscureText = false,
    this.autofocus = false,
    this.autovalidateMode,
    this.readOnly = false,
    this.textInputAction,
    this.enabled = true,
    this.maxLines = 1,
    this.initialValue,
    this.keyboardType,
    this.onSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.controller,
    this.onChanged,
    this.validator,
    this.formKey,
    super.key,
  }) : variant = .custom,
       label = null,
       hint = null,
       assert(
         controller == null || initialValue == null,
         'Use either controller or initialValue, not both.',
       );

  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final GlobalKey<FormState>? formKey;
  final TextInputType? keyboardType;
  final AppTextFieldVariant variant;
  final InputDecoration? decoration;
  final String? initialValue;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;
  final bool autofocus;
  final bool readOnly;
  final int? maxLines;
  final bool enabled;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      .floatingLabel => _buildFloatingLabel(context),
      .custom => _buildCustom(context),
      .label => _buildLabel(context),
    };
  }

  Widget _buildFloatingLabel(BuildContext context) {
    final theme = context.flushipTheme;

    return _maybeForm(
      _buildField(
        context,
        _AppTextFieldDecoration.floatingLabel(
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          theme: theme,
          label: label!,
          hint: hint!,
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final theme = context.flushipTheme;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: theme.spacing.sm,
      children: [
        AppText.custom(
          label!,
          color: enabled ? theme.colors.section : theme.colors.textDim,
          weight: .w500,
        ),
        _maybeForm(
          _buildField(
            context,
            _AppTextFieldDecoration.hintOnly(
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              theme: theme,
              hint: hint!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustom(BuildContext context) {
    return _maybeForm(
      _buildField(
        context,
        decoration!.copyWith(
          suffixIcon: suffixIcon ?? decoration!.suffixIcon,
          prefixIcon: prefixIcon ?? decoration!.prefixIcon,
        ),
      ),
    );
  }

  Widget _maybeForm(Widget child) {
    if (formKey == null) return child;
    return Form(key: formKey, child: child);
  }

  Widget _buildField(BuildContext context, InputDecoration fieldDecoration) {
    final inputTheme = Theme.of(context).inputDecorationTheme;
    final colors = context.flushipTheme.colors;

    return TextFormField(
      autovalidateMode:
          autovalidateMode ??
          (validator != null ? .onUserInteraction : .disabled),
      initialValue: controller == null ? initialValue : null,
      decoration: fieldDecoration.applyDefaults(inputTheme),
      style: _AppTextFieldDecoration.textStyle(colors),
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      cursorColor: colors.accent,
      keyboardType: keyboardType,
      obscureText: obscureText,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      autofocus: autofocus,
      readOnly: readOnly,
      maxLines: maxLines,
      enabled: enabled,
    );
  }
}
