import 'package:fluship/core/app_theme/mappers/app_theme_data_mapper.dart';
import 'package:fluship/core/app_theme/presets/one_dark.dart';
import 'package:fluship/shared/app_layout/developer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders compact icon-only social actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: const OneDarkPreset().lightTheme.toThemeData(brightness: .light),
        home: const Scaffold(
          body: SizedBox(width: 260, child: DeveloperCard()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Senpai'), findsOneWidget);
    expect(find.text('Creator of Fluship'), findsOneWidget);
    expect(find.byTooltip('LinkedIn'), findsOneWidget);
    expect(find.byTooltip('YouTube'), findsOneWidget);
    expect(find.byTooltip('GitHub'), findsOneWidget);
    expect(find.text('LinkedIn'), findsNothing);
    expect(find.text('YouTube'), findsNothing);
    expect(find.text('GitHub'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
