import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/pipeline/widgets/top_builder.dart';
import 'package:fluship/features/layout_wrapper.dart';
import 'package:flutter/material.dart';

class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.flushipTheme.spacing;

    return LayoutWrapper(
      child: SingleChildScrollView(
        padding: .all(spacing.md),
        child: Column(children: [TopBuilder(spacing: spacing)]),
      ),
    );
  }
}
