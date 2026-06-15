import 'package:flutter/material.dart';

import '../models/breakpoint_config.dart';
import '../models/responsive_info.dart';

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    this.maxWidth = 1200,
    required this.child,
    this.padding,
    this.config,
    super.key,
  });

  final EdgeInsetsGeometry? padding;
  final BreakpointConfig? config;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final info = ResponsiveInfo.fromContext(context, config: config);

    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (info.isMobile) return content;

    return Align(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}
