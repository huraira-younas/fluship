import 'package:fluship/features/file_manager/models/file_entry.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

class const FileManagerEntryTile({
  required final VoidCallback onToggleSelection,
  required final VoidCallback onOpenDirectory,
  required final bool hasSelection,
  required final bool canOpenFile,
  required final VoidCallback onOpenFile,
  required final bool isSelected,
  required final FileEntry entry,
  super.key,
}) extends StatelessWidget {
  static const _trailingSlotWidth = 18.0;
  static const _leadingSlotWidth = 24.0;
  static const _tileHeight = 52.0;

  void _handleTap() {
    if (hasSelection) return onToggleSelection();
    if (entry.isDirectory) return onOpenDirectory();
    onOpenFile();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    onToggleSelection();
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final subtitle = entry.isDirectory
        ? null
        : _buildFileSubtitle(entry.sizeBytes, entry.modified);

    return Material(
      color: isSelected
          ? ft.colors.hover.withValues(alpha: 0.25)
          : Colors.transparent,
      child: InkWell(
        onLongPress: _handleLongPress,
        onTap: _handleTap,
        child: SizedBox(
          height: _tileHeight,
          child: Row(
            crossAxisAlignment: .center,
            spacing: ft.spacing.md,
            children: [
              if (hasSelection)
                SizedBox(
                  height: _leadingSlotWidth,
                  width: _leadingSlotWidth,
                  child: Checkbox(
                    side: BorderSide(color: ft.colors.cardBorder),
                    onChanged: (_) => onToggleSelection(),
                    materialTapTargetSize: .shrinkWrap,
                    activeColor: ft.colors.accent,
                    checkColor: ft.colors.bg,
                    visualDensity: .compact,
                    value: isSelected,
                  ),
                ),
              Icon(
                entry.isDirectory
                    ? Icons.folder_outlined
                    : (canOpenFile
                          ? Icons.description_outlined
                          : Icons.insert_drive_file_outlined),
                color: entry.isDirectory ? ft.colors.accent : ft.colors.textDim,
                size: 22,
              ),
              Column(
                mainAxisAlignment: .center,
                crossAxisAlignment: .start,
                spacing: 2,
                children: [
                  AppText.body(entry.name, overflow: .ellipsis, maxLines: 1),
                  if (subtitle != null) AppText.caption(subtitle),
                ],
              ).expanded(),
              SizedBox(
                height: _trailingSlotWidth,
                width: _trailingSlotWidth,
                child: !hasSelection && !entry.isDirectory
                    ? Icon(
                        canOpenFile ? Icons.open_in_new : Icons.block,
                        color: ft.colors.textDim,
                        size: _trailingSlotWidth,
                      )
                    : null,
              ),
            ],
          ),
        ).padSym(h: ft.spacing.lg),
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
