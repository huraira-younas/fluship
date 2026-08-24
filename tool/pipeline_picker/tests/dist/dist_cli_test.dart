import 'dart:io';

import '../../dist/dist_cli.dart';
import '../../io_helpers.dart';

void main() {
  _check(
    playValidation(
          saJsonPath: '',
          packageName: '',
          aabPath: '',
          track: 'beta',
        )?.code ==
        64,
    'bad track',
  );
  _check(
    playValidation(
          saJsonPath: '',
          packageName: 'com.app',
          aabPath: '/tmp/x.aab',
          track: 'production',
        )?.code ==
        1,
    'missing play secrets',
  );

  final root = Directory.systemTemp.createTempSync('fluship-dist-');
  try {
    final sa = File(pathJoin(root.path, 'sa.json'))..writeAsStringSync('{}');
    final aab = File(pathJoin(root.path, 'app.aab'))..writeAsBytesSync([1]);
    _check(
      playValidation(
            saJsonPath: sa.path,
            packageName: 'com.app',
            aabPath: aab.path,
            track: 'internal',
          ) ==
          null,
      'play ok',
    );
    _check(
      resolveOneArtifact(
            explicit: aab.path,
            outputDir: root.path,
            extension: '.aab',
          ) ==
          aab.path,
      'explicit aab',
    );

    _check(
      driveValidation(oauthJson: '', tokenJson: '', files: const [])?.code == 1,
      'drive secrets',
    );
    final oauth = File(pathJoin(root.path, 'oauth.json'))
      ..writeAsStringSync('{}');
    _check(
      driveValidation(
            oauthJson: oauth.path,
            tokenJson: '',
            files: [aab.path],
          )?.message.contains('Fluship Settings') ==
          true,
      'drive token hint',
    );
    final token = File(pathJoin(root.path, 'token.json'))
      ..writeAsStringSync('{}');
    final apk = File(pathJoin(root.path, 'app-release.apk'))
      ..writeAsBytesSync([1]);
    _check(
      driveValidation(
            oauthJson: oauth.path,
            tokenJson: token.path,
            files: [apk.path],
          ) ==
          null,
      'drive ok',
    );

    _check(
      appStoreValidation(
            isMacOS: false,
            issuerId: 'i',
            apiKeyId: 'k',
            apiKeyPath: token.path,
            ipaPath: apk.path,
          )?.message.contains('macOS') ==
          true,
      'app store os',
    );
    final p8 = File(pathJoin(root.path, 'key.p8'))..writeAsStringSync('k');
    final ipa = File(pathJoin(root.path, 'app.ipa'))..writeAsBytesSync([1]);
    _check(
      appStoreValidation(
            isMacOS: true,
            issuerId: 'issuer',
            apiKeyId: 'key',
            apiKeyPath: p8.path,
            ipaPath: ipa.path,
          ) ==
          null,
      'app store ok',
    );

    _check(
      slackValidation(webhookUrl: '', link: 'https://x')?.code == 1,
      'slack secret',
    );
    _check(
      slackValidation(
            webhookUrl: 'https://hooks.slack.com/x',
            link: '',
          )?.code ==
          1,
      'slack link',
    );
    _check(
      slackValidation(
            webhookUrl: 'https://hooks.slack.com/x',
            link: 'https://drive.google.com/x',
          ) ==
          null,
      'slack ok',
    );
    _check(
      driveValidation(
            oauthJson: '{"installed":{}}',
            tokenJson: token.path,
            files: [apk.path],
          )?.message.contains('OAuth') ==
          true,
      'drive oauth must be a file',
    );

    final last = pathJoin(root.path, 'last-drive.json');
    writeLastDrive(
      path: last,
      link: 'https://drive.google.com/x',
      fileNames: ['a.apk'],
    );
    _check(
      readLastDriveLink(last) == 'https://drive.google.com/x',
      'last drive',
    );
  } finally {
    root.deleteSync(recursive: true);
  }
  stdout.writeln('dist cli tests: ok');
}

void _check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
