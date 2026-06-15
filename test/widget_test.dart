import 'package:flutter_test/flutter_test.dart';

import 'package:fluship/app.dart';

void main() {
  testWidgets('App renders with default theme', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Fluship'), findsOneWidget);
    expect(find.text('Theme: catppuccin_mocha'), findsOneWidget);
  });
}
