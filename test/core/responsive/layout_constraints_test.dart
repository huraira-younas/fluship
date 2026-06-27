import 'package:fluship/core/responsive/models/layout_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutConstraints', () {
    test('material3 defaults', () {
      final constraints = LayoutConstraints.material3;

      expect(constraints.minWidth, 360);
      expect(constraints.maxWidth, double.infinity);
    });

    test('supports custom minimum mobile width', () {
      final constraints = const LayoutConstraints(minWidth: 390);

      expect(constraints.minWidth, 390);
    });
  });
}
