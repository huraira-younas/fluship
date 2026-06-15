import 'package:fluship/core/responsive/models/layout_constraints.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class LayoutWrapper extends StatelessWidget {
  LayoutWrapper({
    this.floatingActionButton,
    this.centerBody = false,
    required this.child,
    this.padding,
    this.actions,
    this.title,
    super.key,
  }) : minWidth = LayoutConstraints.material3.minMobileWidth;

  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;
  final List<Widget>? actions;
  final double minWidth;
  final bool centerBody;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      appBar: title != null
          ? AppBar(title: AppText.headline(title!), actions: actions)
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;

          if (!viewportWidth.isFinite || viewportWidth >= minWidth) {
            return child;
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: minWidth, child: child),
          );
        },
      ),
    );
  }
}
