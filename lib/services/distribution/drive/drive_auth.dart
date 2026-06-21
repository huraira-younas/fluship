import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:url_launcher/url_launcher.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show File;

const _driveScope = 'https://www.googleapis.com/auth/drive';

abstract interface class DriveAuthClientFactory {
  Future<http.Client> createClient({
    required String oauthJsonPath,
    String? tokenJsonPath,
  });
}

class GoogleDriveAuthClientFactory implements DriveAuthClientFactory {
  const GoogleDriveAuthClientFactory();

  @override
  Future<http.Client> createClient({
    required String oauthJsonPath,
    String? tokenJsonPath,
  }) async {
    final clientId = await _loadClientId(oauthJsonPath);
    final scopes = [_driveScope];
    final httpClient = http.Client();

    final tokenPath = tokenJsonPath?.trim();
    if (tokenPath != null && tokenPath.isNotEmpty) {
      final refreshToken = await _loadRefreshToken(tokenPath);
      if (refreshToken != null) {
        return clientViaRefreshToken(
          baseClient: httpClient,
          clientId,
          refreshToken,
          scopes,
        );
      }
    }

    final credentials = await obtainAccessCredentialsViaUserConsent(
      clientId,
      scopes,
      httpClient,
      (url) async {
        final uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: .externalApplication)) {
          throw StateError(
            'Could not open browser for Google Drive auth: $url',
          );
        }
      },
    );

    if (credentials.refreshToken == null) {
      throw StateError('No refresh token received; cannot reuse credentials.');
    }

    if (tokenPath != null && tokenPath.isNotEmpty) {
      await _persistCredentials(credentials, tokenPath);
    }

    return autoRefreshingClient(clientId, credentials, httpClient);
  }

  Future<ClientId> _loadClientId(String oauthJsonPath) async {
    final raw =
        jsonDecode(await File(oauthJsonPath).readAsString())
            as Map<String, dynamic>;
    final installed =
        raw['installed'] as Map<String, dynamic>? ??
        raw['web'] as Map<String, dynamic>?;

    if (installed == null) {
      throw StateError(
        'Invalid OAuth client JSON: missing installed/web block.',
      );
    }

    return ClientId(
      installed['client_id'] as String,
      installed['client_secret'] as String?,
    );
  }

  Future<String?> _loadRefreshToken(String tokenPath) async {
    final file = File(tokenPath);
    if (!await file.exists()) return null;

    final stored =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final refreshToken = stored['refresh_token'] as String?;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    return refreshToken;
  }

  Future<void> _persistCredentials(
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
}
