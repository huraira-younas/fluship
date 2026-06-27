import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import 'package:fluship/app.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs.i.init();
    AppLocator.initialize();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('App renders pipeline screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Run Pipeline'), findsWidgets);
    expect(find.text('Ready when you are'), findsOneWidget);
  });
}
