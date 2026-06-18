import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:fluship/core/validator_builder.dart';
import 'package:flutter/material.dart';

class AddRecipientSheet extends StatefulWidget {
  const AddRecipientSheet({super.key});

  static Future<DistributionEmail?> show(BuildContext context) {
    return showModalBottomSheet<DistributionEmail>(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      context: context,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const AddRecipientSheet(),
        ).padOnly(b: bottom).align(align: .bottomCenter);
      },
    );
  }

  @override
  State<AddRecipientSheet> createState() => _AddRecipientSheetState();
}

class _AddRecipientSheetState extends State<AddRecipientSheet> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _nameValidator = ValidatorBuilder.chain()
      .required('Name is required')
      .build();

  final _emailValidator = ValidatorBuilder.chain()
      .required('Email is required')
      .email()
      .build();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    Navigator.of(context).pop(
      DistributionEmail(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return Material(
      color: ft.colors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: .all(.circular(ft.radius.card)),
        side: BorderSide(color: ft.colors.cardBorder),
      ),
      child: Padding(
        padding: .fromLTRB(
          ft.spacing.lg,
          ft.spacing.md,
          ft.spacing.lg,
          ft.spacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: .circular(99),
                  color: ft.colors.cardBorder,
                ),
                height: 4,
                width: 40,
              ).center(),
              SizedBox(height: ft.spacing.lg),
              const AppText.title('Add recipient'),
              const SizedBox(height: 6),
              const AppText.label(
                'People on this list receive build artifacts and distribution emails.',
              ),
              SizedBox(height: ft.spacing.lg),
              AppTextField.label(
                autovalidateMode: .onUserInteraction,
                controller: _nameController,
                validator: _nameValidator,
                hint: 'Alice Johnson',
                label: 'Name',
              ),
              SizedBox(height: ft.spacing.md),
              AppTextField.label(
                autovalidateMode: .onUserInteraction,
                controller: _emailController,
                keyboardType: .emailAddress,
                validator: _emailValidator,
                hint: 'alice@example.com',
                label: 'Email',
              ),
              SizedBox(height: ft.spacing.lg),
              Row(
                children: [
                  AppButton.ghost(
                    onPressed: () => Navigator.of(context).pop(),
                    label: 'Cancel',
                  ).expanded(),
                  SizedBox(width: ft.spacing.sm),
                  AppButton.primary(
                    label: 'Add recipient',
                    onPressed: _submit,
                  ).expanded(),
                ],
              ),
            ],
          ),
        ),
      ),
    ).padAll(ft.spacing.sm);
  }
}
