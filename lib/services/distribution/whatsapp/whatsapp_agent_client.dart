import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show File;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'whatsapp_client.dart';

class const WhatsAppAgentClient({
  final Duration retryDelay = const Duration(seconds: 5),
  final http.Client? _httpClient,
}) implements WhatsAppClient {
  static const baseUrl = 'https://api.whatsapp.com/agent/v1';

  /// A slow send must not be mistaken for a failed one, because retrying a
  /// message that did go out delivers it twice.
  static const _sendTimeout = Duration(seconds: 90);
  static const _uploadTimeout = Duration(minutes: 3);
  static const _maxUpdatePages = 5;

  @override
  Future<void> sendText({
    required String token,
    required String body,
    required String to,
  }) {
    return _postMessage(token, {
      'messaging_product': 'whatsapp',
      'type': 'text',
      'to': to,
      'text': {'body': body, 'preview_url': true},
    });
  }

  @override
  Future<void> sendDocument({
    required String fileName,
    required String mediaId,
    required String token,
    required String to,
    String? caption,
  }) {
    return _postMessage(token, {
      'messaging_product': 'whatsapp',
      'type': 'document',
      'to': to,
      'document': {
        'filename': fileName,
        'id': mediaId,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
    });
  }

  @override
  Future<String> uploadDocument({
    required String mimeType,
    required String token,
    required String path,
  }) async {
    final file = File(path);
    final length = await file.length();
    final uri = Uri.parse('$baseUrl/media');

    final response = await _withClient(
      (client) => _send(
        timeout: _uploadTimeout,
        client,
        () => http.MultipartRequest('POST', uri)
          ..headers.addAll(_authHeaders(token))
          ..fields['messaging_product'] = 'whatsapp'
          ..fields['type'] = mimeType
          ..files.add(
            http.MultipartFile(
              'file',
              file.openRead(),
              length,
              filename: p.basename(path),
            ),
          ),
      ),
    );

    final id = _decodeObject(response.body)['id'];
    if (id is! String || id.isEmpty) {
      throw WhatsAppApiException(
        message: 'WhatsApp accepted the file but returned no media id.',
        statusCode: response.statusCode,
      );
    }
    return id;
  }

  @override
  Future<String?> findCreatorId({required String token}) {
    return _withClient((client) async {
      String? found;
      var offset = 0;

      for (var page = 0; page < _maxUpdatePages; page++) {
        final uri = Uri.parse('$baseUrl/updates').replace(
          queryParameters: {
            'offset': '$offset',
            'limit': '100',
            'timeout': '0',
          },
        );

        final response = await _send(
          client,
          () => http.Request('GET', uri)..headers.addAll(_authHeaders(token)),
          timeout: _sendTimeout,
        );

        // 204: nothing at or after this offset.
        if (response.statusCode == 204 || response.body.trim().isEmpty) break;

        final body = _decodeObject(response.body);
        found = creatorIdFromUpdates(body) ?? found;

        final next = body['next_offset'];
        if (next is! int || next <= offset) break;
        offset = next;
      }

      return found;
    });
  }

  /// The newest `user:<id>` in one `/updates` response. Messages come first
  /// because they are what the creator just sent; contacts and receipts
  /// name the same account and cover a page that holds no message.
  static String? creatorIdFromUpdates(Map<String, dynamic> body) {
    String? fromMessages;
    String? fromOthers;

    for (final entry in _list(body['entry'])) {
      for (final change in _list(_map(entry)['changes'])) {
        final value = _map(_map(change)['value']);

        for (final message in _list(value['messages'])) {
          final from = _map(message)['from'];
          if (_isUserId(from)) fromMessages = from as String;
        }
        for (final contact in _list(value['contacts'])) {
          final id = _map(contact)['wa_id'];
          if (_isUserId(id)) fromOthers = id as String;
        }
        for (final status in _list(value['statuses'])) {
          final id = _map(status)['recipient_id'];
          if (_isUserId(id)) fromOthers = id as String;
        }
      }
    }

    return fromMessages ?? fromOthers;
  }

  Future<void> _postMessage(String token, Map<String, Object?> payload) {
    final uri = Uri.parse('$baseUrl/messages');
    final encoded = jsonEncode(payload);

    return _withClient(
      (client) => _send(
        timeout: _sendTimeout,
        client,
        () => http.Request('POST', uri)
          ..headers.addAll(_authHeaders(token))
          ..headers['Content-Type'] = 'application/json'
          ..body = encoded,
      ),
    );
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer ${token.trim()}',
  };

  Future<T> _withClient<T>(Future<T> Function(http.Client client) run) async {
    final shared = _httpClient;
    if (shared != null) return run(shared);

    final client = http.Client();
    try {
      return await run(client);
    } finally {
      client.close();
    }
  }

  /// Sends once, and once more for the two answers the API documents as
  /// "not sent, try again": 429 and 503. A 500 is left alone because the
  /// message may already have gone out.
  Future<http.Response> _send(
    http.Client client,
    http.BaseRequest Function() build, {
    required Duration timeout,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final streamed = await client.send(build()).timeout(timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(timeout);

      final status = response.statusCode;
      if (status >= 200 && status < 300) return response;

      final error = errorFromResponse(status, response.body);
      if (attempt == 0 && error.isRetryable) {
        await Future.pause(retryDelay);
        continue;
      }
      throw error;
    }
  }

  static WhatsAppApiException errorFromResponse(int status, String body) {
    Map<String, dynamic> error = const {};
    try {
      error = _map(_decodeObject(body)['error']);
    } catch (_) {}

    final rawCode = error['code'];
    final code = rawCode is int ? rawCode : int.tryParse('$rawCode');
    final details = _map(error['error_data'])['details'];
    final summary = error['message'];
    final detail = details is String && details.trim().isNotEmpty
        ? details.trim()
        : summary is String && summary.trim().isNotEmpty
        ? summary.trim()
        : 'no details given';

    final message = switch ((status, code)) {
      (401, _) ||
      (_, 190) => 'WhatsApp did not accept the API key. Check it in Settings.',
      (403, _) || (_, 131005) =>
        'WhatsApp refused the recipient: an agent can only message the '
            'account that created it. Press Connect again in Settings.',
      (409, _) || (_, 1752041) =>
        'Another program is reading updates for this agent. Stop it and '
            'try again.',
      (429, _) ||
      (_, 130429) => 'WhatsApp rate limit reached. Try again in a minute.',
      (_, 131053) => 'WhatsApp rejected the file: $detail',
      (_, 131016) => 'WhatsApp did not accept the message for delivery.',
      (_, 100) =>
        'WhatsApp rejected the request ($detail). If the API key was '
            'regenerated, update it in Settings.',
      _ =>
        'WhatsApp API error $status'
            '${code == null ? '' : ' (code $code)'}: $detail',
    };

    return WhatsAppApiException(
      statusCode: status,
      message: message,
      code: code,
    );
  }

  static Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static List<Object?> _list(Object? value) => value is List ? value : const [];

  static bool _isUserId(Object? value) =>
      value is String && value.startsWith('user:') && value.length > 5;
}
