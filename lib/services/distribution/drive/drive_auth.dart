import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show File;

const driveScope = 'https://www.googleapis.com/auth/drive';

abstract interface class DriveAuthClientFactory {
  Future<http.Client> createClient({
    required String oauthJsonPath,
    String? tokenJsonPath,
  });
}

/// Refresh-token auth only. Safe for `dart run` CLIs (no Flutter).
class GoogleDriveTokenAuthClientFactory implements DriveAuthClientFactory {
  const GoogleDriveTokenAuthClientFactory();

  @override
  Future<http.Client> createClient({
    required String oauthJsonPath,
    String? tokenJsonPath,
  }) async {
    final clientId = await loadDriveClientId(oauthJsonPath);
    final tokenPath = tokenJsonPath?.trim() ?? '';
    final refreshToken = tokenPath.isEmpty
        ? null
        : await loadDriveRefreshToken(tokenPath);
    if (refreshToken == null) {
      throw StateError(
        'Drive token is missing. Auth once in Fluship Settings.',
      );
    }
    return clientViaRefreshToken(
      baseClient: http.Client(),
      clientId,
      refreshToken,
      [driveScope],
    );
  }
}

Future<ClientId> loadDriveClientId(String oauthJsonPath) async {
  final raw =
      jsonDecode(await File(oauthJsonPath).readAsString())
          as Map<String, dynamic>;
  final installed =
      raw['installed'] as Map<String, dynamic>? ??
      raw['web'] as Map<String, dynamic>?;

  if (installed == null) {
    throw StateError('Invalid OAuth client JSON: missing installed/web block.');
  }

  return ClientId(
    installed['client_id'] as String,
    installed['client_secret'] as String?,
  );
}

Future<String?> loadDriveRefreshToken(String tokenPath) async {
  final file = File(tokenPath);
  if (!await file.exists()) return null;

  final stored = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final refreshToken = stored['refresh_token'] as String?;
  if (refreshToken == null || refreshToken.isEmpty) return null;
  return refreshToken;
}

Future<void> persistDriveCredentials(
  AccessCredentials credentials,
  String tokenPath,
) async {
  await File(tokenPath).writeAsString(
    jsonEncode({
      'expiry': credentials.accessToken.expiry.toIso8601String(),
      'access_token': credentials.accessToken.data,
      'token_type': credentials.accessToken.type,
      'refresh_token': credentials.refreshToken,
    }),
  );
}
