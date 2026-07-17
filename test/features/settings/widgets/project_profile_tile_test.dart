import 'package:fluship/core/app_theme/mappers/app_theme_data_mapper.dart';
import 'package:fluship/core/app_theme/presets/one_dark.dart';
import 'package:fluship/features/settings/widgets/project_profile_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders tile colors and ink on a Material surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: const OneDarkPreset().lightTheme.toThemeData(brightness: .light),
        home: const Scaffold(
          body: ProjectProfileTile(
            projectPath: '/projects/reelstay',
            projectName: 'reelstay',
            selected: true,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(Material), findsWidgets);
    expect(find.text('reelstay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
