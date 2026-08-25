import 'dart:io';

import '../io_helpers.dart';
import 'readiness.dart';

enum SecretFieldKind { text, password, file }

/// Where a panel field is stored. Keys live in secrets.json, except the report
/// recipient, which every run reads from pipeline-cache.json.
enum SecretStore { secrets, cache }

class SecretField {
  const SecretField({
    required this.key,
    required this.label,
    required this.hint,
    this.kind = SecretFieldKind.text,
    this.prompt = '',
    this.fileTypes = const <String>[],
    this.optional = false,
    this.store = SecretStore.secrets,
  });

  final String key;
  final String label;
  final String hint;
  final SecretFieldKind kind;
  final String prompt;
  final List<String> fileTypes;
  final bool optional;
  final SecretStore store;

  bool get isFile => kind == SecretFieldKind.file;
  bool get isPassword => kind == SecretFieldKind.password;
}

class SecretGroup {
  const SecretGroup({
    required this.id,
    required this.title,
    required this.blurb,
    required this.fields,
    this.macOnly = false,
  });

  final String id;
  final String title;
  final String blurb;
  final List<SecretField> fields;
  final bool macOnly;
}

const secretGroups = <SecretGroup>[
  SecretGroup(
    id: 'play',
    title: 'Google Play Console',
    blurb:
        'Package name and the Google Cloud service account JSON that lets '
        'Fluship upload an AAB to Play.',
    fields: [
      SecretField(
        key: 'playPackageName',
        label: 'Package name',
        hint: 'com.example.my_app',
      ),
      SecretField(
        key: 'playSaJsonPath',
        label: 'Service account JSON',
        hint: '/Users/you/keys/play_service_account.json',
        kind: SecretFieldKind.file,
        prompt: 'Select the Play service account JSON',
        fileTypes: ['json'],
      ),
    ],
  ),
  SecretGroup(
    id: 'appStore',
    title: 'App Store Connect',
    blurb:
        'API credentials for TestFlight. Create a key in App Store Connect '
        'under Users and Access, then pick the downloaded .p8 file.',
    macOnly: true,
    fields: [
      SecretField(
        key: 'appStoreIssuerId',
        label: 'Issuer id',
        hint: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
      ),
      SecretField(
        key: 'appStoreApiKeyId',
        label: 'API key id',
        hint: 'XXXXXXXXXX',
      ),
      SecretField(
        key: 'appStoreApiKeyPath',
        label: 'Auth key (.p8)',
        hint: '/Users/you/keys/AuthKey_XXXXXXXXXX.p8',
        kind: SecretFieldKind.file,
        prompt: 'Select the App Store Connect API key (.p8)',
        fileTypes: ['p8'],
      ),
    ],
  ),
  SecretGroup(
    id: 'drive',
    title: 'Google Drive',
    blurb:
        'OAuth client JSON from Google Cloud Console. A saved token file skips '
        'the browser consent next time, and a parent folder id decides where '
        'the APKs land.',
    fields: [
      SecretField(
        key: 'driveOauthJson',
        label: 'OAuth client JSON',
        hint: '/Users/you/keys/oauth_client.json',
        kind: SecretFieldKind.file,
        prompt: 'Select the Drive OAuth client JSON',
        fileTypes: ['json'],
      ),
      SecretField(
        key: 'driveTokenJson',
        label: 'Token JSON',
        hint: '/Users/you/keys/drive_token.json',
        kind: SecretFieldKind.file,
        prompt: 'Select the Drive token JSON',
        fileTypes: ['json'],
        optional: true,
      ),
      SecretField(
        key: 'driveFolderId',
        label: 'Parent folder id',
        hint: '1k21HPdFxA8Xa8R9qh7CBcB6A6TtE0kQF',
        optional: true,
      ),
    ],
  ),
  SecretGroup(
    id: 'slack',
    title: 'Slack webhook',
    blurb:
        'Paste the web request URL from your Slack workflow trigger. Fluship '
        'posts the app, version, status, and the Drive link.',
    fields: [
      SecretField(
        key: 'slackWebhookUrl',
        label: 'Web request URL',
        hint: 'https://hooks.slack.com/triggers/T000/000',
      ),
    ],
  ),
  SecretGroup(
    id: 'report',
    title: 'Email report',
    blurb:
        'Gmail address plus an app password from Google Account, Security, '
        '2-Step Verification. The recipient gets the HTML report and logs.txt.',
    fields: [
      SecretField(
        key: 'gmailAddress',
        label: 'Gmail address',
        hint: 'you@gmail.com',
      ),
      SecretField(
        key: 'appPassword',
        label: 'App password',
        hint: '16 characters, no spaces',
        kind: SecretFieldKind.password,
      ),
      SecretField(
        key: 'emailRecipient',
        label: 'Report recipient',
        hint: 'reports@example.com',
        store: SecretStore.cache,
      ),
    ],
  ),
];

List<SecretGroup> secretGroupsForHost({required bool isMacOS}) {
  return [
    for (final group in secretGroups)
      if (isMacOS || !group.macOnly) group,
  ];
}

Iterable<SecretField> get secretFields {
  return secretGroups.expand((group) => group.fields);
}

/// The panel payload the browser renders. Passwords go out blank with a
/// `saved` flag so a stored one is never echoed back over the wire.
Map<String, dynamic> secretsPanelJson({
  required Map<String, dynamic> secrets,
  required Map<String, String> cacheValues,
  required bool isMacOS,
}) {
  final facts = SecretsFacts.fromJson(secrets);
  return {
    'groups': [
      for (final group in secretGroupsForHost(isMacOS: isMacOS))
        {
          'id': group.id,
          'title': group.title,
          'blurb': group.blurb,
          'ready': facts.readyFor(group.id),
          'fields': [
            for (final field in group.fields)
              _fieldJson(field, _valueFor(field, secrets, cacheValues)),
          ],
        },
    ],
  };
}

Map<String, dynamic> _fieldJson(SecretField field, String value) {
  return {
    'key': field.key,
    'label': field.label,
    'hint': field.hint,
    'kind': field.kind.name,
    'prompt': field.prompt,
    'fileTypes': field.fileTypes,
    'optional': field.optional,
    'value': field.isPassword ? '' : value,
    'saved': value.isNotEmpty,
    'missingFile':
        field.isFile && value.isNotEmpty && !secretFileOrJsonPresent(value),
  };
}

String _valueFor(
  SecretField field,
  Map<String, dynamic> secrets,
  Map<String, String> cacheValues,
) {
  return switch (field.store) {
    SecretStore.secrets => asString(secrets[field.key]),
    SecretStore.cache => asString(cacheValues[field.key]),
  };
}

/// Folds panel edits into the saved secrets. A blank password keeps the stored
/// one, since the panel never sends it back. Any other blank clears its key,
/// and keys outside the catalog are ignored.
Map<String, dynamic> mergeSecrets({
  required Map<String, dynamic> existing,
  required Map<String, dynamic> incoming,
}) {
  final merged = <String, dynamic>{...existing};
  for (final field in secretFields) {
    if (field.store != SecretStore.secrets) continue;
    if (!incoming.containsKey(field.key)) continue;
    final value = asString(incoming[field.key]);
    if (value.isEmpty) {
      if (!field.isPassword) merged.remove(field.key);
      continue;
    }
    merged[field.key] = value;
  }
  return merged;
}

/// Writes secrets.json, then narrows it to owner-only where chmod exists.
void writeSecretsFile(String path, Map<String, dynamic> secrets) {
  writeJsonFile(path, secrets);
  if (Platform.isWindows) return;
  try {
    Process.runSync('chmod', ['600', path]);
  } catch (_) {}
}
