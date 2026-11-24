import 'package:material_ui/material_ui.dart';

import '../models/breakpoint_config.dart';
import '../models/responsive_info.dart';

class const ResponsiveContainer({
  final double maxWidth = 1200,
  required final Widget child,
  final EdgeInsetsGeometry? padding,
  final BreakpointConfig? config,
  super.key,
}) extends StatelessWidget {
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
