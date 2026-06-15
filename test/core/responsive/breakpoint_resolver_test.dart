import 'package:fluship/core/responsive/utils/breakpoint_resolver.dart';
import 'package:fluship/core/responsive/models/breakpoint_config.dart';
import 'package:fluship/core/responsive/models/app_breakpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveBreakpoint', () {
    const config = BreakpointConfig.material3();

    test('returns compact below 600', () {
      expect(resolveBreakpoint(0, config), AppBreakpoint.compact);
      expect(resolveBreakpoint(599, config), AppBreakpoint.compact);
    });

    test('returns medium between 600 and 839', () {
      expect(resolveBreakpoint(600, config), AppBreakpoint.medium);
      expect(resolveBreakpoint(839, config), AppBreakpoint.medium);
    });

    test('returns expanded between 840 and 1199', () {
      expect(resolveBreakpoint(840, config), AppBreakpoint.expanded);
      expect(resolveBreakpoint(1199, config), AppBreakpoint.expanded);
    });

    test('returns large between 1200 and 1599', () {
      expect(resolveBreakpoint(1200, config), AppBreakpoint.large);
      expect(resolveBreakpoint(1599, config), AppBreakpoint.large);
    });

    test('returns extraLarge at 1600 and above', () {
      expect(resolveBreakpoint(1600, config), AppBreakpoint.extraLarge);
      expect(resolveBreakpoint(2000, config), AppBreakpoint.extraLarge);
    });

    test('respects custom config thresholds', () {
      const custom = BreakpointConfig(
        expandedMax: 1000,
        compactMax: 400,
        mediumMax: 700,
        largeMax: 1400,
      );

      expect(resolveBreakpoint(400, custom), AppBreakpoint.compact);
      expect(resolveBreakpoint(401, custom), AppBreakpoint.medium);
      expect(resolveBreakpoint(701, custom), AppBreakpoint.expanded);
      expect(resolveBreakpoint(1001, custom), AppBreakpoint.large);
      expect(resolveBreakpoint(1401, custom), AppBreakpoint.extraLarge);
    });
  });
}
