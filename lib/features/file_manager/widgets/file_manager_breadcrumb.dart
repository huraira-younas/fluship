import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:fluship/shared/widgets/app_text.dart';
import '../bloc/file_manager_bloc.dart';

class FileManagerBreadcrumb extends StatelessWidget {
  const FileManagerBreadcrumb({required this.segments, super.key});

  final List<FileManagerSegment> segments;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    if (segments.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Row(
        children: [
          for (var index = 0; index < segments.length; index++) ...[
            if (index > 0)
              Padding(
                padding: .symmetric(horizontal: ft.spacing.sm),
                child: Icon(
                  Icons.chevron_right,
                  color: ft.colors.textDim,
                  size: 18,
                ),
              ),
            _BreadcrumbChip(
              isLast: index == segments.length - 1,
              segment: segments[index],
              index: index,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({
    required this.isLast,
    required this.segment,
    required this.index,
  });

  final FileManagerSegment segment;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return InkWell(
      onTap: isLast
          ? null
          : () => context.read<FileManagerBloc>().add(
              FileManagerNavigateToSegment(index: index),
            ),
      borderRadius: .circular(ft.radius.btn),
      child: Padding(
        padding: .symmetric(
          horizontal: ft.spacing.sm,
          vertical: ft.spacing.sm - 4,
        ),
        child: AppText.custom(
          segment.name,
          color: isLast ? ft.colors.text : ft.colors.accent,
          size: .caption,
          weight: isLast ? .w600 : .w500,
        ),
      ),
    );
  }
}
