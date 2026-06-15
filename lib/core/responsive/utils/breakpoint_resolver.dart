import '../models/breakpoint_config.dart';
import '../models/app_breakpoint.dart';

AppBreakpoint resolveBreakpoint(double width, BreakpointConfig config) {
  if (width <= config.compactMax) return .compact;
  if (width <= config.mediumMax) return .medium;
  if (width <= config.expandedMax) return .expanded;
  if (width <= config.largeMax) return .large;
  return .extraLarge;
}
