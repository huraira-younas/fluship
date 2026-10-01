import 'package:fluship/core/app_theme/mappers/app_theme_data_mapper.dart';
import 'package:fluship/core/app_theme/presets/one_dark.dart';
import 'package:fluship/shared/app_layout/developer_card.dart';
import 'package:material_ui/material_ui.dart';
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

  testWidgets('keeps the name and socials on one row when the card is wide', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: const OneDarkPreset().lightTheme.toThemeData(brightness: .light),
        home: const Scaffold(
          body: SizedBox(width: 640, child: DeveloperCard()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Senpai'), findsOneWidget);
    expect(find.text('Creator of Fluship'), findsOneWidget);
    expect(find.byTooltip('GitHub'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow in a narrow side panel', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: const OneDarkPreset().darkTheme.toThemeData(brightness: .dark),
        home: const Scaffold(
          body: SizedBox(width: 140, child: DeveloperCard()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Senpai'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
