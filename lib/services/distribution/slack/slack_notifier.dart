import 'package:http/http.dart' as http;
import 'dart:convert' show jsonEncode;

typedef SlackPoster = Future<void> Function(Uri url, String body);

class SlackNotifier {
  const SlackNotifier({this.post});

  final SlackPoster? post;

  static String statusFromNames(Iterable<String> names) {
    final submittedTo = [
      for (final name in names)
        if (name.trim().isNotEmpty) name.trim(),
    ];
    return submittedTo.isEmpty
        ? 'Artifacts for QA'
        : '${submittedTo.join(', ')} submitted';
  }

  static String statusLine({required bool playStore, required bool appStore}) {
    return statusFromNames([
      if (playStore) 'PlayStore',
      if (appStore) 'AppStore',
    ]);
  }

  static Map<String, String> payload({
    required String buildNumber,
    required String artifacts,
    required String platform,
    required String version,
    required String status,
    required String app,
  }) {
    return {
      'version': '$version+$buildNumber',
      'artifacts': artifacts,
      'platform': platform,
      'status': status,
      'app': app,
    };
  }

  Future<void> send({
    required Map<String, String> body,
    required String webhookUrl,
  }) async {
    final url = Uri.parse(webhookUrl);
    final encoded = jsonEncode(body);
    final poster = post;
    if (poster != null) {
      await poster(url, encoded);
      return;
    }
    final response = await http.post(
      headers: {'Content-Type': 'application/json'},
      body: encoded,
      url,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Slack webhook failed (${response.statusCode}).');
    }
  }
}
