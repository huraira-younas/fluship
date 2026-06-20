import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:fluship/shared/widgets/app_text.dart';
import '../bloc/file_manager_bloc.dart';

class FileManagerBreadcrumb extends StatefulWidget {
  const FileManagerBreadcrumb({
    required this.currentPath,
    required this.segments,
    super.key,
  });

  final List<FileManagerSegment> segments;
  final String currentPath;

  @override
  State<FileManagerBreadcrumb> createState() => _FileManagerBreadcrumbState();
}

class _FileManagerBreadcrumbState extends State<FileManagerBreadcrumb> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant FileManagerBreadcrumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments ||
        oldWidget.currentPath != widget.currentPath) {
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    if (widget.segments.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: .horizontal,
      child: Row(
        children: [
          for (var index = 0; index < widget.segments.length; index++) ...[
            if (index > 0)
              Icon(
                color: ft.colors.textDim,
                Icons.chevron_right,
                size: 18,
              ).padSym(h: ft.spacing.sm),
            _BreadcrumbChip(
              index: index,
              segment: widget.segments[index],
              isActive: p.equals(
                widget.segments[index].path,
                widget.currentPath,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({
    required this.isActive,
    required this.segment,
    required this.index,
  });

  final FileManagerSegment segment;
  final bool isActive;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => context.read<FileManagerBloc>().add(
          FileManagerNavigateToSegment(index: index),
        ),
        borderRadius: .circular(ft.radius.btn),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isActive ? ft.colors.hover.withValues(alpha: 0.35) : null,
            borderRadius: .circular(ft.radius.btn),
          ),
          child: AppText.custom(
            color: isActive ? ft.colors.text : ft.colors.accent,
            weight: isActive ? .w600 : .w500,
            size: .caption,
            segment.name,
          ).padSym(h: ft.spacing.sm + 2, v: ft.spacing.sm - 2),
        ),
      ),
    );
  }
}
