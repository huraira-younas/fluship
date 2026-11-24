import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../utils/breakpoint_resolver.dart';
import 'breakpoint_config.dart';
import 'app_breakpoint.dart';

enum AppOrientationLock {
  landscape,
  portrait,
  all;

  List<DeviceOrientation> get preferredOrientations => switch (this) {
    .landscape => const <DeviceOrientation>[.landscapeLeft, .landscapeRight],
    .portrait => const <DeviceOrientation>[.portraitUp, .portraitDown],
    .all => DeviceOrientation.values,
  };
}

class const ResponsiveInfo({
  required final Orientation orientation,
  required final AppBreakpoint breakpoint,
  required final double height,
  required final double width,
}) extends Equatable {
  bool get isTabletOrMobile => isMobile || isTablet;
  bool get isMobile => breakpoint == .compact;
  bool get isTablet => breakpoint == .medium;

  bool get isDesktop =>
      breakpoint == .extraLarge ||
      breakpoint == .expanded ||
      breakpoint == .large;

  bool get isLandscape => orientation == .landscape;
  bool get isPortrait => orientation == .portrait;

  static Future<void> setOrientationLock(AppOrientationLock lock) {
    return SystemChrome.setPreferredOrientations(lock.preferredOrientations);
  }

  static Future<void> clearOrientationLock() {
    return setOrientationLock(.all);
  }

  factory fromContext(BuildContext context, {BreakpointConfig? config}) {
    final breakpointConfig = config ?? const BreakpointConfig.material3();
    final mediaQuery = MediaQuery.sizeOf(context);

    return ResponsiveInfo(
      breakpoint: resolveBreakpoint(mediaQuery.width, breakpointConfig),
      orientation: MediaQuery.orientationOf(context),
      height: mediaQuery.height,
      width: mediaQuery.width,
    );
  }

  @override
  List<Object?> get props => [orientation, breakpoint, height, width];
}
