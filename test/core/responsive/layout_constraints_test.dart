import 'package:fluship/core/responsive/models/layout_constraints.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io' show Platform;

void main() {
  group('LayoutConstraints', () {
    test('material3 defaults', () {
      final constraints = LayoutConstraints.material3;

      expect(constraints.minWidth, 360);
      expect(constraints.maxWidth, Platform.isWindows ? 1380 : 1080);
    });

    test('supports custom minimum mobile width', () {
      final constraints = LayoutConstraints(minWidth: 390);

      expect(constraints.minWidth, 390);
    });
  });
}
