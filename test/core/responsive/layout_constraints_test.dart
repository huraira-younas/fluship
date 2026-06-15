import 'package:fluship/core/responsive/models/layout_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutConstraints', () {
    test('material3 defaults', () {
      const constraints = LayoutConstraints.material3;

      expect(constraints.minWidth, 360);
      expect(constraints.maxWidth, 1080);
    });

    test('supports custom minimum mobile width', () {
      const constraints = LayoutConstraints(minWidth: 390);

      expect(constraints.minWidth, 390);
    });
  });
}
