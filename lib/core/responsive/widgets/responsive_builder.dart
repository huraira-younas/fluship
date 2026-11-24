import 'package:material_ui/material_ui.dart';

import '../models/breakpoint_config.dart';
import '../models/responsive_info.dart';

class const ResponsiveBuilder({
  required final Widget Function(BuildContext context, ResponsiveInfo info)
  builder,
  final BreakpointConfig? config,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final info = ResponsiveInfo.fromContext(context, config: config);

    return builder(context, info);
  }
}
