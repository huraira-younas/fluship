import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:io';

import 'package:fluship/services/distribution/distribution.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _token = 'secret-agent-key';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _error(int status, int code, {String? details}) => _json({
  'error': {
    'message': '(#$code) Something went wrong',
    'type': 'OAuthException',
    'code': code,
    'error_data': {'messaging_product': 'whatsapp', 'details': ?details},
  },
}, status);

Map<String, Object?> _updates({
  List<Map<String, Object?>> messages = const [],
  List<Map<String, Object?>> statuses = const [],
  required int nextOffset,
}) => {
  'object': 'whatsapp_agent_platform',
  'entry': [
    {
      'id': '123',
      'changes': [
        {
          'field': 'messages',
          'value': {
            'messaging_product': 'whatsapp',
            'messages': messages,
            'statuses': statuses,
          },
        },
      ],
    },
  ],
  'next_offset': nextOffset,
};

WhatsAppAgentClient _client(MockClient mock) =>
    WhatsAppAgentClient(httpClient: mock, retryDelay: .zero);

void main() {
  group('sendText', () {
    test('posts the text to the messages endpoint with the key', () async {
      late http.Request seen;
      final client = _client(
        MockClient((request) async {
          seen = request;
          return _json({
            'messages': [
              {'id': 'wamid.1'},
            ],
          });
        }),
      );

      await client.sendText(token: ' $_token ', to: 'user:1', body: 'Hello');

      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://api.whatsapp.com/agent/v1/messages');
      expect(seen.headers['Authorization'], 'Bearer $_token');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), {
        'messaging_product': 'whatsapp',
        'type': 'text',
        'to': 'user:1',
        'text': {'body': 'Hello', 'preview_url': true},
      });
    });

    test('retries once after a rate limit', () async {
      var calls = 0;
      final client = _client(
        MockClient((_) async {
          calls++;
          return calls == 1 ? _error(429, 130429) : _json({'messages': []});
        }),
      );

      await client.sendText(token: _token, to: 'user:1', body: 'Hello');

      expect(calls, 2);
    });

    test('does not retry a 500, which may already have sent', () async {
      var calls = 0;
      final client = _client(
        MockClient((_) async {
          calls++;
          return _error(500, 2);
        }),
      );

      await expectLater(
        client.sendText(token: _token, to: 'user:1', body: 'Hello'),
        throwsA(isA<WhatsAppApiException>()),
      );
      expect(calls, 1);
    });

    test('explains a recipient that is not the creator', () async {
      final client = _client(MockClient((_) async => _error(403, 131005)));

      await expectLater(
        client.sendText(token: _token, to: 'user:2', body: 'Hello'),
        throwsA(
          isA<WhatsAppApiException>()
              .having((e) => e.code, 'code', 131005)
              .having((e) => e.message, 'message', contains('Connect again')),
        ),
      );
    });

    test('never puts the key in an error message', () async {
      final statuses = [
        (401, 190),
        (400, 100),
        (403, 131005),
        (500, 2),
        (503, 131016),
        (418, 999),
      ];

      for (final (status, code) in statuses) {
        final client = _client(
          MockClient((_) async => _error(status, code, details: 'bad input')),
        );

        try {
          await client.sendText(token: _token, to: 'user:1', body: 'Hello');
          fail('expected an error for $status');
        } on WhatsAppApiException catch (error) {
          expect('$error', isNot(contains(_token)));
          expect(error.statusCode, status);
        }
      }
    });

    test('survives an error body that is not JSON', () {
      final error = WhatsAppAgentClient.errorFromResponse(502, '<html>');

      expect(error.statusCode, 502);
      expect(error.message, contains('502'));
    });
  });

  group('documents', () {
    late Directory dir;
    late File log;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('fluship_whatsapp_');
      log = File('${dir.path}/logs.txt');
      await log.writeAsString('line one\nline two\n');
    });

    tearDown(() => dir.delete(recursive: true));

    test('uploads the file as multipart and returns the media id', () async {
      late String contentType;
      late String body;
      late Uri url;
      String? auth;

      final client = _client(
        MockClient.streaming((request, bodyStream) async {
          contentType = request.headers['content-type'] ?? '';
          auth = request.headers['Authorization'];
          body = await utf8.decodeStream(bodyStream);
          url = request.url;
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({'id': 'media-1'}))),
            200,
          );
        }),
      );

      final id = await client.uploadDocument(
        mimeType: 'text/plain',
        path: log.path,
        token: _token,
      );

      expect(id, 'media-1');
      expect(url.toString(), 'https://api.whatsapp.com/agent/v1/media');
      expect(auth, 'Bearer $_token');
      expect(contentType, startsWith('multipart/form-data'));
      expect(body, contains('name="messaging_product"'));
      expect(body, contains('whatsapp'));
      expect(body, contains('name="type"'));
      expect(body, contains('text/plain'));
      expect(body, contains('name="file"; filename="logs.txt"'));
      expect(body, contains('line one\nline two'));
    });

    test('fails when the upload returns no media id', () async {
      final client = _client(MockClient((_) async => _json({})));

      await expectLater(
        client.uploadDocument(
          mimeType: 'text/plain',
          path: log.path,
          token: _token,
        ),
        throwsA(isA<WhatsAppApiException>()),
      );
    });

    test('reports a rejected file', () async {
      final client = _client(
        MockClient(
          (_) async => _error(400, 131053, details: 'File is 20 MB, limit 16'),
        ),
      );

      await expectLater(
        client.uploadDocument(
          mimeType: 'text/plain',
          path: log.path,
          token: _token,
        ),
        throwsA(
          isA<WhatsAppApiException>().having(
            (e) => e.message,
            'message',
            contains('File is 20 MB'),
          ),
        ),
      );
    });

    test('sends a document message that names the media id', () async {
      late http.Request seen;
      final client = _client(
        MockClient((request) async {
          seen = request;
          return _json({'messages': []});
        }),
      );

      await client.sendDocument(
        fileName: 'Demo-logs.txt',
        caption: 'Pipeline log',
        mediaId: 'media-1',
        token: _token,
        to: 'user:1',
      );

      expect(jsonDecode(seen.body), {
        'messaging_product': 'whatsapp',
        'type': 'document',
        'to': 'user:1',
        'document': {
          'filename': 'Demo-logs.txt',
          'id': 'media-1',
          'caption': 'Pipeline log',
        },
      });
    });
  });

  group('findCreatorId', () {
    test('reads the newest sender across pages from offset 0', () async {
      final offsets = <String?>[];
      final client = _client(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/agent/v1/updates');
          expect(request.url.queryParameters['timeout'], '0');
          expect(request.headers['Authorization'], 'Bearer $_token');

          final offset = request.url.queryParameters['offset'];
          offsets.add(offset);
          return switch (offset) {
            '0' => _json(
              _updates(
                nextOffset: 5,
                messages: [
                  {'from': 'user:111', 'type': 'text'},
                ],
              ),
            ),
            '5' => _json(
              _updates(
                nextOffset: 9,
                messages: [
                  {'from': 'user:222', 'type': 'text'},
                ],
              ),
            ),
            _ => http.Response('', 204),
          };
        }),
      );

      expect(await client.findCreatorId(token: _token), 'user:222');
      expect(offsets, ['0', '5', '9']);
    });

    test('returns null when the agent has no updates', () async {
      final client = _client(MockClient((_) async => http.Response('', 204)));

      expect(await client.findCreatorId(token: _token), isNull);
    });

    test('falls back to a receipt when a page holds no message', () {
      final body = _updates(
        nextOffset: 2,
        statuses: [
          {'id': 'wamid.1', 'status': 'read', 'recipient_id': 'user:333'},
        ],
      );

      expect(
        WhatsAppAgentClient.creatorIdFromUpdates(
          jsonDecode(jsonEncode(body)) as Map<String, dynamic>,
        ),
        'user:333',
      );
    });

    test('ignores ids that are not a WhatsApp user', () {
      final body = _updates(
        nextOffset: 2,
        messages: [
          {'from': 'agent:9'},
          {'from': 'user:'},
          {'from': 42},
        ],
      );

      expect(
        WhatsAppAgentClient.creatorIdFromUpdates(
          jsonDecode(jsonEncode(body)) as Map<String, dynamic>,
        ),
        isNull,
      );
    });

    test('stops paging when the offset does not advance', () async {
      var calls = 0;
      final client = _client(
        MockClient((_) async {
          calls++;
          return _json(_updates(nextOffset: 0));
        }),
      );

      expect(await client.findCreatorId(token: _token), isNull);
      expect(calls, 1);
    });

    test('explains a competing poller', () async {
      final client = _client(MockClient((_) async => _error(409, 1752041)));

      await expectLater(
        client.findCreatorId(token: _token),
        throwsA(
          isA<WhatsAppApiException>().having(
            (e) => e.message,
            'message',
            contains('Another program'),
          ),
        ),
      );
    });
  });
}
