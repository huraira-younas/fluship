import 'dart:convert' show jsonDecode;

import 'package:fluship/services/distribution/slack/slack_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payload matches the GUI Slack fields', () {
    final body = SlackNotifier.payload(
      app: 'Demo App',
      version: '1.0.0',
      buildNumber: '42',
      platform: 'Android',
      artifacts: 'https://drive.google.com/drive/folders/abc',
      status: SlackNotifier.statusLine(playStore: false, appStore: false),
    );

    expect(body, {
      'version': '1.0.0+42',
      'platform': 'Android',
      'artifacts': 'https://drive.google.com/drive/folders/abc',
      'app': 'Demo App',
      'status': 'Artifacts for QA',
    });
  });

  test('statusFromNames matches statusLine', () {
    expect(SlackNotifier.statusFromNames(const []), 'Artifacts for QA');
    expect(
      SlackNotifier.statusFromNames(const ['PlayStore', 'AppStore']),
      SlackNotifier.statusLine(playStore: true, appStore: true),
    );
  });

  test('status lists PlayStore and AppStore when those tracks are on', () {
    expect(
      SlackNotifier.statusLine(playStore: true, appStore: false),
      'PlayStore submitted',
    );
    expect(
      SlackNotifier.statusLine(playStore: true, appStore: true),
      'PlayStore, AppStore submitted',
    );
  });

  test('send posts JSON to the webhook', () async {
    Uri? url;
    String? raw;
    final notifier = SlackNotifier(
      post: (postedUrl, body) async {
        url = postedUrl;
        raw = body;
      },
    );

    await notifier.send(
      webhookUrl: 'https://hooks.slack.com/x',
      body: SlackNotifier.payload(
        app: 'Demo App',
        version: '1.0.0',
        buildNumber: '42',
        platform: 'Android',
        artifacts: 'https://drive.example/link',
        status: 'Artifacts for QA',
      ),
    );

    expect(url.toString(), 'https://hooks.slack.com/x');
    expect(jsonDecode(raw!), {
      'version': '1.0.0+42',
      'platform': 'Android',
      'artifacts': 'https://drive.example/link',
      'app': 'Demo App',
      'status': 'Artifacts for QA',
    });
  });
}
