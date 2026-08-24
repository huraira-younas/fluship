import 'dart:io';

import 'package:fluship/services/distribution/slack/slack_notifier.dart';

import 'pipeline_picker/dist/dist_cli.dart';
import 'pipeline_picker/io_helpers.dart';

Future<void> main(List<String> args) async {
  await runDistMain(args: args, usage: _usage, run: _run);
}

Future<void> _run(Map<String, String> parsed) async {
  final agent = loadAgentJson(parsed);
  final lastDrive = resolveAgentPath(parsed['last-drive'], 'last-drive.json');
  final link = (parsed['link'] ?? readLastDriveLink(lastDrive)).trim();
  final failure = slackValidation(
    webhookUrl: secretString(agent.secrets, 'slackWebhookUrl'),
    link: link,
  );
  if (failure != null) {
    stderr.writeln(failure.message);
    exitCode = failure.code;
    return;
  }

  await const SlackNotifier().send(
    webhookUrl: secretString(agent.secrets, 'slackWebhookUrl'),
    body: SlackNotifier.payload(
      app: parsed['app-name'] ?? asString(agent.cache['appName'], 'Fluship'),
      version: parsed['version'] ?? asString(agent.cache['version'], '0.0.0'),
      buildNumber:
          parsed['build-number'] ?? asString(agent.cache['buildNumber'], '0'),
      platform: parsed['platforms'] ?? 'unknown',
      artifacts: link,
      status: SlackNotifier.statusFromNames([
        for (final part in (parsed['submitted'] ?? '').split(','))
          if (part.trim().isNotEmpty) part.trim(),
      ]),
    ),
  );
  stdout.writeln('Slack notify sent');
}

const _usage = '''
Post a Drive link to Slack.

  dart run tool/slack_notify.dart --link <url> --app-name NAME --version VER --build-number NUM

Reads slackWebhookUrl from .fluship-agent/secrets.json.
''';
