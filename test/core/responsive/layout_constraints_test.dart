import 'package:fluship/core/responsive/models/layout_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutConstraints', () {
    test('material3 defaults', () {
      const constraints = LayoutConstraints.material3;

      expect(constraints.minMobileWidth, 360);
      expect(constraints.maxDesktopWidth, 1200);
    });

    test('supports custom minimum mobile width', () {
      const constraints = LayoutConstraints(minMobileWidth: 390);

      expect(constraints.minMobileWidth, 390);
    });
  });
}
