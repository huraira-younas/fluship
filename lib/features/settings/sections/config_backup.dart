import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'dart:convert' show JsonEncoder, jsonDecode;
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import 'dart:io' show File;

class ConfigBackup extends StatelessWidget {
  const ConfigBackup({super.key});

  Future<void> _export() async {
    final bloc = getIt<ConfigBloc>();
    final json = bloc.exportConfig();
    
    final projectName = bloc.state.activeProject ?? 'fluship';
    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(json);

    final path = await getIt<FilePickerService>().saveFile(
      fileName: '${projectName}_config.json',
      dialogTitle: 'Export Fluship Config',
      allowedExtensions: ['json'],
    );

    if (path == null) return;

    final filePath = path.endsWith('.json') ? path : '$path.json';
    await File(filePath).writeAsString(content);
    AppToast.success('Config exported successfully.');
  }

  Future<void> _import(BuildContext context) async {
    final path = await getIt<FilePickerService>().pickFile(
      dialogTitle: 'Import Fluship Config',
      allowedExtensions: ['json'],
    );

    if (path == null) return;
    if (!context.mounted) return;

    final confirmed = await _confirmImport(context);
    if (!confirmed) return;

    try {
      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      getIt<ConfigBloc>().add(
        ImportConfig(
          data: data,
          onError: (e) => AppToast.error(e.message),
          onSuccess: (_) => AppToast.success('Config imported successfully.'),
        ),
      );
    } catch (e) {
      AppToast.error('Invalid config file: $e');
    }
  }

  Future<bool> _confirmImport(BuildContext context) async {
    final ft = context.flushipTheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ft.colors.cardBg,
        title: const AppText.title('Replace current config?'),
        content: const AppText.body(
          'Importing will overwrite all your current pipeline settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const AppText.body('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const AppText.danger('Import'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Config Backup',
      description:
          'Export your pipeline config as JSON or import a previously saved one.',
      spacing: 15,
      children: [
        Row(
          spacing: 10,
          children: [
            AppButton.outline(label: 'Export', onPressed: _export),
            AppButton.outline(
              onPressed: () => _import(context),
              label: 'Import',
            ),
          ],
        ),
      ],
    );
  }
}
