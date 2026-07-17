import 'package:fluship/core/app_theme/mappers/app_theme_data_mapper.dart';
import 'package:fluship/core/app_theme/presets/one_dark.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildField(String? value) {
    return MaterialApp(
      theme: const OneDarkPreset().lightTheme.toThemeData(brightness: .light),
      home: Scaffold(
        body: AppTextField.label(
          initialValue: value,
          onChanged: (_) {},
          label: 'Credential',
          hint: 'Enter value',
        ),
      ),
    );
  }

  testWidgets('updates displayed text when initial value changes', (
    tester,
  ) async {
    await tester.pumpWidget(buildField(null));

    final before = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(before.controller?.text, isEmpty);

    await tester.pumpWidget(buildField('imported value'));
    await tester.pump();

    final after = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(after.controller?.text, 'imported value');
  });
}
