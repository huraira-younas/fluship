import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluship/core/responsive/models/app_breakpoint.dart';
import 'package:fluship/core/responsive/models/responsive_info.dart';

void main() {
  group('AppOrientationLock', () {
    test('all allows every device orientation', () {
      expect(
        AppOrientationLock.all.preferredOrientations,
        DeviceOrientation.values,
      );
    });

    test('portrait allows only portrait orientations', () {
      expect(
        AppOrientationLock.portrait.preferredOrientations,
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );
    });

    test('landscape allows only landscape orientations', () {
      expect(
        AppOrientationLock.landscape.preferredOrientations,
        const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
    });
  });

  group('ResponsiveInfo orientation helpers', () {
    test('isPortrait and isLandscape reflect orientation', () {
      const portrait = ResponsiveInfo(
        orientation: Orientation.portrait,
        breakpoint: AppBreakpoint.compact,
        height: 800,
        width: 360,
      );

      const landscape = ResponsiveInfo(
        orientation: Orientation.landscape,
        breakpoint: AppBreakpoint.compact,
        height: 360,
        width: 800,
      );

      expect(portrait.isPortrait, isTrue);
      expect(portrait.isLandscape, isFalse);
      expect(landscape.isPortrait, isFalse);
      expect(landscape.isLandscape, isTrue);
    });
  });
}
