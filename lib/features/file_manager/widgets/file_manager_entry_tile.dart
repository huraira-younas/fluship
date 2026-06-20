import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/file_manager/models/file_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fluship/shared/widgets/app_text.dart';

class FileManagerEntryTile extends StatelessWidget {
  const FileManagerEntryTile({
    required this.onOpenDirectory,
    required this.canOpenFile,
    required this.onOpenFile,
    required this.entry,
    super.key,
  });

  final VoidCallback onOpenDirectory;
  final VoidCallback onOpenFile;
  final bool canOpenFile;
  final FileEntry entry;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final modified = entry.modified;
    final subtitle = entry.isDirectory
        ? 'Folder'
        : _buildFileSubtitle(entry.sizeBytes, modified);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.isDirectory ? onOpenDirectory : onOpenFile,
        child: Padding(
          padding: .symmetric(
            horizontal: ft.spacing.lg,
            vertical: ft.spacing.md,
          ),
          child: Row(
            spacing: ft.spacing.md,
            children: [
              Icon(
                entry.isDirectory
                    ? Icons.folder_outlined
                    : (canOpenFile ? Icons.description_outlined : Icons.insert_drive_file_outlined),
                color: entry.isDirectory ? ft.colors.accent : ft.colors.textDim,
                size: 22,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    AppText.body(
                      entry.name,
                      overflow: .ellipsis,
                      maxLines: 1,
                    ),
                    AppText.caption(subtitle),
                  ],
                ),
              ),
              if (!entry.isDirectory)
                Icon(
                  canOpenFile ? Icons.open_in_new : Icons.block,
                  color: ft.colors.textDim,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFileSubtitle(int? sizeBytes, DateTime? modified) {
    final parts = <String>[];

    if (sizeBytes != null) {
      parts.add(_formatSize(sizeBytes));
    }

    if (modified != null) {
      parts.add(DateFormat('MMM d, yyyy · HH:mm').format(modified));
    }

    return parts.isEmpty ? 'File' : parts.join(' · ');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
