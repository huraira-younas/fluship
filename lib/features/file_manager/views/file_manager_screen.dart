import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/di/locator.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_text.dart';

import '../repository/file_manager_repository.dart';
import '../widgets/file_manager_breadcrumb.dart';
import '../widgets/file_manager_entry_tile.dart';
import '../bloc/file_manager_bloc.dart';
import '../routes.dart';

class FileManagerScreen extends StatelessWidget {
  const FileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = getIt<FileManagerRepository>();
    final ft = context.flushipTheme;

    return Scaffold(
      backgroundColor: ft.colors.bg,
      appBar: AppBar(
        backgroundColor: ft.colors.bg,
        foregroundColor: ft.colors.text,
        title: const AppText.title('File Manager'),
      ),
      body: BlocBuilder<FileManagerBloc, FileManagerState>(
        builder: (context, state) {
          if (state.loading && state.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Padding(
                padding: .all(ft.spacing.lg),
                child: Column(
                  mainAxisSize: .min,
                  spacing: ft.spacing.md,
                  children: [
                    AppText.danger(state.error!.message, textAlign: .center),
                    const AppText.label(
                      'Make sure the outputs folder exists after running a pipeline.',
                      textAlign: .center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: .stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: ft.colors.cardBorder),
                  ),
                  color: ft.colors.cardBg,
                ),
                padding: .symmetric(
                  horizontal: ft.spacing.lg,
                  vertical: ft.spacing.md,
                ),
                child: FileManagerBreadcrumb(segments: state.segments),
              ),
              if (state.loading)
                LinearProgressIndicator(
                  backgroundColor: ft.colors.cardBorder,
                  color: ft.colors.accent,
                  minHeight: 2,
                ),
              if (state.entries.isEmpty)
                const AppText.label('This folder is empty.').center().expanded()
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: state.entries.length,
                    separatorBuilder: (_, _) => Divider(
                      color: ft.colors.cardBorder,
                      height: 1,
                      indent: ft.spacing.lg + 34,
                    ),
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      final canOpenFile = repository.isTextFile(entry.path);

                      return FileManagerEntryTile(
                        canOpenFile: canOpenFile,
                        entry: entry,
                        onOpenDirectory: () => context
                            .read<FileManagerBloc>()
                            .add(FileManagerOpenDirectory(path: entry.path)),
                        onOpenFile: () {
                          if (canOpenFile) {
                            FileManagerRoutes.openTextViewer(entry.path);
                            return;
                          }

                          AppToast.info(
                            'Only text files can be opened in the file manager.',
                            title: entry.name,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
