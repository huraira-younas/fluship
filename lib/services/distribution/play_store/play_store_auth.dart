import 'package:googleapis/androidpublisher/v3.dart' as androidpublisher;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonDecode;
import 'dart:io' show File;

abstract interface class PlayStoreAuthClientFactory {
  Future<http.Client> createClient({required String saJsonPath});
}

class GooglePlayAuthClientFactory implements PlayStoreAuthClientFactory {
  const GooglePlayAuthClientFactory();

  @override
  Future<http.Client> createClient({required String saJsonPath}) async {
    final path = saJsonPath.trim();
    if (path.isEmpty) {
      throw StateError('Service account JSON path is missing.');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Service account JSON not found at $path.');
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final credentials = ServiceAccountCredentials.fromJson(json);

    return clientViaServiceAccount(credentials, [
      androidpublisher.AndroidPublisherApi.androidpublisherScope,
    ]);
  }
}
