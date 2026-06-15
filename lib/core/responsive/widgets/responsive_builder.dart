import 'package:flutter/material.dart';

import '../models/breakpoint_config.dart';
import '../models/responsive_info.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, this.config, super.key});

  final Widget Function(BuildContext context, ResponsiveInfo info) builder;
  final BreakpointConfig? config;

  @override
  Widget build(BuildContext context) {
    final info = ResponsiveInfo.fromContext(context, config: config);

    return builder(context, info);
  }
}
