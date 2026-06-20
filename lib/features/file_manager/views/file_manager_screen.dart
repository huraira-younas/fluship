import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../widgets/file_manager_delete_dialog.dart';
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

    return BlocConsumer<FileManagerBloc, FileManagerState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null,
      listener: (_, s) {
        AppToast.error(s.error!.message, title: s.error!.title);
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.hasSelection,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;

            context.read<FileManagerBloc>().add(
              const FileManagerClearSelection(),
            );
          },
          child: Scaffold(
            backgroundColor: ft.colors.bg,
            appBar: AppBar(
              actions: [_buildActions(ft, state, context)],
              foregroundColor: ft.colors.text,
              backgroundColor: ft.colors.bg,
              title: _buildTitle(state),
              leading: state.hasSelection
                  ? IconButton(
                      tooltip: 'Cancel selection',
                      onPressed: () => context.read<FileManagerBloc>().add(
                        const FileManagerClearSelection(),
                      ),
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
            body: _buildBody(repository, ft, state, context),
          ),
        );
      },
    );
  }

  Widget _buildTitle(FileManagerState state) {
    if (state.hasSelection) {
      final count = state.selectedPaths.length;
      return AppText.title(count == 1 ? '1 selected' : '$count selected');
    }

    return const AppText.title('File Manager');
  }

  Widget _buildActions(
    FlushipThemeExtension ft,
    FileManagerState state,
    BuildContext context,
  ) {
    final entries = state.entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    final bloc = context.read<FileManagerBloc>();

    if (state.hasSelection) {
      final allSelected = entries.every(
        (e) => state.selectedPaths.contains(p.normalize(e.path)),
      );

      return Row(
        spacing: ft.spacing.md,
        mainAxisSize: .min,
        children: [
          AppButton.ghost(
            label: allSelected ? 'Deselect all' : 'Select all',
            onPressed: () {
              if (allSelected) {
                bloc.add(const FileManagerClearSelection());
                return;
              }

              bloc.add(const FileManagerSelectAll());
            },
          ),
          AppButton.danger(
            onPressed: () => _deleteSelected(state, context),
            label: 'Delete',
          ),
        ],
      ).padOnly(r: ft.spacing.md);
    }

    return AppButton.ghost(
      onPressed: () => bloc.add(const FileManagerSelectAll()),
      label: 'Select',
    ).padOnly(r: ft.spacing.md);
  }

  Widget _buildBody(
    FileManagerRepository repository,
    FlushipThemeExtension ft,
    FileManagerState state,
    BuildContext context,
  ) {
    if (state.loading && state.entries.isEmpty && state.segments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.segments.isEmpty) {
      return Column(
        spacing: ft.spacing.md,
        mainAxisSize: .min,
        children: [
          AppText.danger(state.error!.message, textAlign: .center),
          const AppText.label(
            'Make sure the outputs folder exists after running a pipeline.',
            textAlign: .center,
          ),
        ],
      ).padAll(ft.spacing.lg).center();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ft.colors.cardBorder)),
            color: ft.colors.cardBg,
          ),
          padding: .symmetric(
            horizontal: ft.spacing.lg,
            vertical: ft.spacing.md,
          ),
          child: FileManagerBreadcrumb(
            currentPath: state.currentPath,
            segments: state.segments,
          ),
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
          ListView.separated(
            itemCount: state.entries.length,
            separatorBuilder: (_, _) => Divider(
              color: ft.colors.cardBorder,
              height: 1,
              indent:
                  ft.spacing.lg +
                  (state.hasSelection ? 24 + ft.spacing.md : 0) +
                  22,
            ),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              final normalizedPath = p.normalize(entry.path);

              final isSelected = state.selectedPaths.contains(normalizedPath);
              final canOpenFile = repository.isTextFile(entry.path);

              return FileManagerEntryTile(
                hasSelection: state.hasSelection,
                canOpenFile: canOpenFile,
                isSelected: isSelected,
                entry: entry,
                onToggleSelection: () => context.read<FileManagerBloc>().add(
                  FileManagerToggleSelection(path: entry.path),
                ),
                onOpenDirectory: () => context.read<FileManagerBloc>().add(
                  FileManagerOpenDirectory(path: entry.path),
                ),
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
          ).expanded(),
      ],
    );
  }

  Future<void> _deleteSelected(
    FileManagerState state,
    BuildContext context,
  ) async {
    final confirmed = await confirmDeleteSelectedItems(
      count: state.selectedPaths.length,
      context: context,
    );

    if (!confirmed || !context.mounted) return;

    context.read<FileManagerBloc>().add(const FileManagerDeleteSelected());
  }
}
