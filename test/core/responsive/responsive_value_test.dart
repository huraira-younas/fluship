import 'package:fluship/core/responsive/utils/responsive_value.dart';
import 'package:fluship/core/responsive/models/app_breakpoint.dart';
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

    test('falls back to nearest smaller breakpoint when value omitted', () {
      final value = pickResponsiveValue(
        breakpoint: AppBreakpoint.extraLarge,
        expanded: 3,
        compact: 1,
      );

      expect(value, 3);
    });

    test('falls back to compact when no smaller values exist', () {
      final value = pickResponsiveValue(
        breakpoint: AppBreakpoint.large,
        compact: 1,
      );

      expect(value, 1);
    });

    test('supports mobile and desktop binary usage', () {
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
