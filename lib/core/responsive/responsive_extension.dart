import 'package:flutter/material.dart';

import 'models/breakpoint_config.dart';
import 'models/responsive_info.dart';
import 'utils/responsive_value.dart';
import 'models/app_breakpoint.dart';

extension ResponsiveContext on BuildContext {
  ResponsiveInfo get responsive => .fromContext(this);

  AppBreakpoint get breakpoint => responsive.breakpoint;
  bool get isDesktop => responsive.isDesktop;
  bool get isMobile => responsive.isMobile;

  T responsiveValue<T>({
    BreakpointConfig? config,
    required T compact,
    T? extraLarge,
    T? expanded,
    T? medium,
    T? large,
  }) {
    final info = config != null
        ? ResponsiveInfo.fromContext(this, config: config)
        : responsive;

    return pickResponsiveValue(
      breakpoint: info.breakpoint,
      extraLarge: extraLarge,
      expanded: expanded,
      compact: compact,
      medium: medium,
      large: large,
    );
  }
}
