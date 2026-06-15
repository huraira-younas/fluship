import 'package:flutter_test/flutter_test.dart';

import 'package:fluship/app.dart';

void main() {
  testWidgets('App renders pipeline screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('ReelStay'), findsOneWidget);
    expect(find.text('Run Pipeline'), findsOneWidget);
  });
}
