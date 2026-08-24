import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'drive_auth.dart';

/// GUI Drive auth. Opens a browser when no refresh token exists.
class GoogleDriveAuthClientFactory implements DriveAuthClientFactory {
  const GoogleDriveAuthClientFactory();

  @override
  Future<http.Client> createClient({
    required String oauthJsonPath,
    String? tokenJsonPath,
  }) async {
    final clientId = await loadDriveClientId(oauthJsonPath);
    final scopes = [driveScope];
    final httpClient = http.Client();

    final tokenPath = tokenJsonPath?.trim();
    if (tokenPath != null && tokenPath.isNotEmpty) {
      final refreshToken = await loadDriveRefreshToken(tokenPath);
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
      await persistDriveCredentials(credentials, tokenPath);
    }

    return autoRefreshingClient(clientId, credentials, httpClient);
  }
}
