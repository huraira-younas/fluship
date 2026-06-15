import 'package:fluship/core/responsive/models/app_breakpoint.dart';
import 'package:fluship/core/responsive/utils/responsive_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickResponsiveValue', () {
    test('returns explicit value for each breakpoint', () {
      final value = pickResponsiveValue(
        breakpoint: AppBreakpoint.large,
        extraLarge: 5,
        expanded: 4,
        compact: 1,
        medium: 2,
        large: 3,
      );

      expect(value, 3);
    });

    test('extraLarge returns compact when extraLarge value omitted', () {
      final value = pickResponsiveValue(
        breakpoint: AppBreakpoint.extraLarge,
        expanded: 3,
        compact: 1,
      );

      expect(value, 1);
    });

    test('expanded falls back to extraLarge when expanded omitted', () {
      final value = pickResponsiveValue(
        breakpoint: AppBreakpoint.expanded,
        extraLarge: 5,
        compact: 1,
      );

      expect(value, 5);
    });

    test('falls back to compact when no earlier order entries exist', () {
      final value = pickResponsiveValue(
        breakpoint: AppBreakpoint.large,
        compact: 1,
      );

      expect(value, 1);
    });

    test('compact uses its own value before later order entries', () {
      expect(
        pickResponsiveValue(
          breakpoint: AppBreakpoint.compact,
          expanded: 3,
          compact: 1,
        ),
        1,
      );

      expect(
        pickResponsiveValue(
          breakpoint: AppBreakpoint.expanded,
          expanded: 3,
          compact: 1,
        ),
        3,
      );
    });

    test('medium falls back to compact when medium omitted', () {
      final value = pickResponsiveValue(
        breakpoint: AppBreakpoint.medium,
        expanded: 3,
        compact: 1,
      );

      expect(value, 1);
    });
  });
}
