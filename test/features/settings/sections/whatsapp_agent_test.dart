import 'dart:async' show Completer;

import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:fluship/core/app_theme/mappers/app_theme_data_mapper.dart';
import 'package:fluship/features/settings/sections/whatsapp_agent.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/core/app_theme/presets/one_dark.dart';
import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/shared/widgets/app_text_field.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluship/di/locator.dart';
import 'package:material_ui/material_ui.dart';

class _FakeWhatsAppClient implements WhatsAppClient {
  String? creatorId = 'user:50972923564215';
  Completer<void>? findGate;
  Object? findError;

  final findTokens = <String>[];
  final sent = <({String token, String to, String body})>[];

  @override
  Future<String?> findCreatorId({required String token}) async {
    findTokens.add(token);
    await findGate?.future;
    if (findError != null) throw findError!;
    return creatorId;
  }

  @override
  Future<void> sendText({
    required String token,
    required String body,
    required String to,
  }) async {
    sent.add((token: token, to: to, body: body));
  }

  @override
  Future<String> uploadDocument({
    required String mimeType,
    required String token,
    required String path,
  }) async => 'media';

  @override
  Future<void> sendDocument({
    required String fileName,
    required String mediaId,
    required String token,
    required String to,
    String? caption,
  }) async {}
}

void main() {
  late _FakeWhatsAppClient client;
  late ConfigBloc bloc;

  WhatsAppConfig? stored() => bloc.state.distribution.whatsappConfig;

  AppButton button(WidgetTester tester, String label) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs.i.init();

    client = _FakeWhatsAppClient();
    getIt.registerSingleton<WhatsAppClient>(client);
  });

  tearDown(() => getIt.reset());

  Future<void> pumpSection(WidgetTester tester) async {
    // Created here, inside the test's fake clock, so that pumping the tester
    // also runs the bloc's event handling.
    bloc = ConfigBloc(ProjectProfilesStore());
    getIt.registerSingleton<ConfigBloc>(bloc);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: const OneDarkPreset().darkTheme.toThemeData(brightness: .dark),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider<ConfigBloc>.value(
              value: bloc,
              child: const WhatsAppAgent(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> enterKey(WidgetTester tester, String key) async {
    await tester.enterText(find.byType(AppTextField), key);
    await tester.pumpAndSettle();
  }

  testWidgets('starts disconnected with both actions disabled', (tester) async {
    await pumpSection(tester);

    expect(find.text('Not connected yet.'), findsOneWidget);
    expect(button(tester, 'Connect').onPressed, isNull);
    expect(button(tester, 'Send test message').onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Connect stores the chat id found for the key', (tester) async {
    await pumpSection(tester);
    await enterKey(tester, '  agent-key  ');

    expect(stored()?.apiKey, 'agent-key');
    expect(button(tester, 'Connect').onPressed, isNotNull);

    await tester.tap(find.widgetWithText(AppButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(client.findTokens, ['agent-key']);
    expect(stored()?.recipientId, 'user:50972923564215');
    expect(stored()?.canSend, isTrue);
    expect(find.text('Connected to your agent chat.'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Reconnect'), findsOneWidget);
    expect(button(tester, 'Send test message').onPressed, isNotNull);
  });

  testWidgets('stays disconnected when the agent has no message yet', (
    tester,
  ) async {
    client.creatorId = null;
    await pumpSection(tester);
    await enterKey(tester, 'agent-key');

    await tester.tap(find.widgetWithText(AppButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(stored()?.recipientId, isNull);
    expect(find.text('Not connected yet.'), findsOneWidget);
    expect(button(tester, 'Connect').isLoading, isFalse);
  });

  testWidgets('recovers when Connect fails', (tester) async {
    client.findError = const WhatsAppApiException(
      message: 'WhatsApp did not accept the API key.',
      statusCode: 401,
    );
    await pumpSection(tester);
    await enterKey(tester, 'bad-key');

    await tester.tap(find.widgetWithText(AppButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(stored()?.recipientId, isNull);
    expect(button(tester, 'Connect').isLoading, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows progress while it is connecting', (tester) async {
    client.findGate = Completer<void>();
    await pumpSection(tester);
    await enterKey(tester, 'agent-key');

    await tester.tap(find.widgetWithText(AppButton, 'Connect'));
    await tester.pump();

    expect(
      tester.widget<AppButton>(find.byType(AppButton).first).isLoading,
      isTrue,
    );

    client.findGate!.complete();
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppButton, 'Reconnect'), findsOneWidget);
  });

  testWidgets('changing the key drops the chat id', (tester) async {
    await pumpSection(tester);
    await enterKey(tester, 'agent-key');
    await tester.tap(find.widgetWithText(AppButton, 'Connect'));
    await tester.pumpAndSettle();
    expect(stored()?.isConnected, isTrue);

    await enterKey(tester, 'another-key');

    expect(stored()?.apiKey, 'another-key');
    expect(stored()?.recipientId, isNull);
    expect(find.text('Not connected yet.'), findsOneWidget);

    await enterKey(tester, '');

    expect(stored()?.apiKey, isNull);
    expect(button(tester, 'Connect').onPressed, isNull);
  });

  testWidgets('sends the test message to the connected chat', (tester) async {
    await pumpSection(tester);
    await enterKey(tester, 'agent-key');
    await tester.tap(find.widgetWithText(AppButton, 'Connect'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Send test message'));
    await tester.pumpAndSettle();

    expect(client.sent, hasLength(1));
    expect(client.sent.single.token, 'agent-key');
    expect(client.sent.single.to, 'user:50972923564215');
    expect(client.sent.single.body, contains('Fluship is connected'));
  });
}
