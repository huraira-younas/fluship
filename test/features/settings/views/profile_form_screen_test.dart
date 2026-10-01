import 'package:fluship/core/app_theme/mappers/app_theme_data_mapper.dart';
import 'package:fluship/core/app_theme/presets/one_dark.dart';
import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/features/settings/views/profile_form_screen.dart';
import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ConfigBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs.i.init();
    bloc = ConfigBloc(ProjectProfilesStore());
  });

  tearDown(() => bloc.close());

  Future<void> pumpForm(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: const OneDarkPreset().darkTheme.toThemeData(brightness: .dark),
        home: BlocProvider<ConfigBloc>.value(
          value: bloc,
          child: const ProfileFormScreen(isAdding: false),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('keeps a single column and app bar on a narrow window', (
    tester,
  ) async {
    await pumpForm(tester, const Size(500, 800));

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Config Backup'), findsOneWidget);
    expect(find.text('Play Store'), findsNothing);
    expect(find.text('Google Play Console'), findsOneWidget);
    expect(find.text('Delivery'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop shows the sidebar and only the active section', (
    tester,
  ) async {
    await pumpForm(tester, const Size(1440, 900));

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Play Store'), findsOneWidget);
    expect(find.text('Config Backup'), findsOneWidget);
    expect(find.text('Google Play Console'), findsNothing);
    expect(find.text('Reports & Recipients'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a sidebar section replaces the detail pane', (
    tester,
  ) async {
    await pumpForm(tester, const Size(1440, 900));

    await tester.tap(find.text('Play Store'));
    await tester.pumpAndSettle();

    expect(find.text('Google Play Console'), findsOneWidget);
    expect(find.text('Config Backup'), findsNothing);
    expect(find.text('Slack Webhook'), findsNothing);

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Reports & Recipients'), findsOneWidget);
    expect(find.text('Google Play Console'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables save until a project is active', (tester) async {
    await pumpForm(tester, const Size(1440, 900));

    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Save Profile'),
    );
    expect(button.onPressed, isNull);
  });
}
