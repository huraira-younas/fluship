import 'dart:io';

import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

const _testTheme = ReportHtmlTheme(
  borderLr: 'border-left:1px solid #1e293b;border-right:1px solid #1e293b;',
  bodyOpen: '<!DOCTYPE html><html><head></head><body><div>',
  cardBorder: '#1e293b',
  success: '#a3be8c',
  section: '#94a3b8',
  textDim: '#64748b',
  accent: '#81a1c1',
  cardBg: '#3b4252',
  error: '#bf616a',
  text: '#eceff4',
  bg: '#2e3440',
);

class FakeDistributionLogger implements DistributionLogger {
  @override
  Future<void> logLine(DistributionResult result) async {}
}

class FakeWhatsAppClient implements WhatsAppClient {
  final calls = <String>[];
  Object? textError;
  Object? uploadError;
  Object? documentError;

  String? textBody;
  String? textTo;
  String? token;
  String? uploadPath;
  String? uploadMime;
  String? documentName;
  String? documentCaption;
  String? documentMediaId;

  @override
  Future<String?> findCreatorId({required String token}) async => 'user:1';

  @override
  Future<void> sendText({
    required String token,
    required String body,
    required String to,
  }) async {
    calls.add('text');
    if (textError != null) throw textError!;
    this.token = token;
    textBody = body;
    textTo = to;
  }

  @override
  Future<String> uploadDocument({
    required String mimeType,
    required String token,
    required String path,
  }) async {
    calls.add('upload');
    if (uploadError != null) throw uploadError!;
    uploadMime = mimeType;
    uploadPath = path;
    return 'media-1';
  }

  @override
  Future<void> sendDocument({
    required String fileName,
    required String mediaId,
    required String token,
    required String to,
    String? caption,
  }) async {
    calls.add('document');
    if (documentError != null) throw documentError!;
    documentMediaId = mediaId;
    documentCaption = caption;
    documentName = fileName;
  }
}

const _connected = WhatsAppConfig(
  recipientId: 'user:50972923564215',
  apiKey: ' agent-key ',
  enabled: true,
);

PipelineRunSnapshot _snapshot({
  List<String> collected = const [],
  Map<String, String> links = const {},
  String logFilePath = '',
}) {
  return PipelineRunSnapshot(
    steps: const [
      PipelineStepView(
        description: 'Compile a signed release APK',
        status: PipelineStepStatus.completed,
        elapsed: Duration(seconds: 3),
        name: 'Build APK',
      ),
      PipelineStepView(
        description: 'Send the build summary and log to WhatsApp',
        status: PipelineStepStatus.running,
        name: 'Send to WhatsApp',
      ),
    ],
    runStatus: PipelineRunStatus.completed,
    totalElapsed: const Duration(seconds: 3),
    finishedAt: DateTime(2026, 6, 20, 14, 30),
    startedAt: DateTime(2026, 6, 20, 14, 29, 57),
    collectedArtifacts: collected,
    artifactsDir: '/tmp/artifacts',
    logFilePath: logFilePath,
    platforms: 'Android',
    appName: 'Demo App',
    buildNumber: '42',
    version: '1.0.0',
    links: links,
  );
}

DistributionContext _context({
  WhatsAppConfig? whatsapp = _connected,
  PipelineRunSnapshot? snapshot,
}) {
  return DistributionContext(
    config: DistributionConfigModel(whatsappConfig: whatsapp),
    snapshot: snapshot ?? _snapshot(),
    logger: FakeDistributionLogger(),
    emailTheme: _testTheme,
  );
}

void main() {
  late FakeWhatsAppClient client;
  late WhatsAppHandler handler;
  late Directory dir;
  late String logPath;

  setUp(() async {
    client = FakeWhatsAppClient();
    handler = WhatsAppHandler(client: client);
    dir = await Directory.systemTemp.createTemp('fluship_whatsapp_handler_');
    logPath = '${dir.path}/logs.txt';
    await File(logPath).writeAsString('pipeline log\n');
  });

  tearDown(() => dir.delete(recursive: true));

  group('skips', () {
    test('when there is no WhatsApp config', () async {
      final result = await handler.run(_context(whatsapp: null));

      expect(result.isSkipped, isTrue);
      expect(client.calls, isEmpty);
    });

    test('when the summary is switched off', () async {
      final result = await handler.run(
        _context(whatsapp: _connected.copyWith(enabled: false)),
      );

      expect(result.isSkipped, isTrue);
      expect(result.message, contains('disabled'));
      expect(client.calls, isEmpty);
    });

    test('when the API key is missing', () async {
      final result = await handler.run(
        _context(
          whatsapp: const WhatsAppConfig(enabled: true, recipientId: 'user:1'),
        ),
      );

      expect(result.isSkipped, isTrue);
      expect(result.message, contains('API key'));
      expect(client.calls, isEmpty);
    });

    test('when the agent was never connected', () async {
      final result = await handler.run(
        _context(whatsapp: const WhatsAppConfig(enabled: true, apiKey: 'key')),
      );

      expect(result.isSkipped, isTrue);
      expect(result.message, contains('Connect'));
      expect(client.calls, isEmpty);
    });
  });

  test('sends the summary, then uploads and sends the log', () async {
    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: logPath)),
    );

    expect(result.isSuccess, isTrue);
    expect(client.calls, ['text', 'upload', 'document']);

    expect(client.token, 'agent-key');
    expect(client.textTo, 'user:50972923564215');
    expect(client.textBody, contains('*Demo App* v1.0.0+42 succeeded'));
    expect(client.textBody, contains('✓ Build APK'));
    expect(client.textBody, isNot(contains('Send to WhatsApp')));

    expect(client.uploadPath, logPath);
    expect(client.uploadMime, 'text/plain');
    expect(client.documentMediaId, 'media-1');
    expect(client.documentName, 'Demo_App_v1.0.0+42-logs.txt');
    expect(client.documentCaption, 'Pipeline log · Demo App v1.0.0+42');
  });

  test('puts the Drive link and the built files in the summary', () async {
    final apk = '${dir.path}/Demo-v1.0.0+42.apk';
    await File(apk).writeAsBytes(List<int>.filled(1024 * 1024, 0));

    await handler.run(
      _context(
        snapshot: _snapshot(
          links: {'Google Drive': 'https://drive.google.com/drive/folders/abc'},
          logFilePath: logPath,
          collected: [apk],
        ),
      ),
    );

    expect(client.textBody, contains('• Demo-v1.0.0+42.apk (1.0 MB)'));
    expect(
      client.textBody,
      contains('Google Drive: https://drive.google.com/drive/folders/abc'),
    );
    // The build itself is never uploaded, only the log.
    expect(client.uploadPath, logPath);
  });

  test('sends only the summary when no log was saved', () async {
    final result = await handler.run(_context());

    expect(result.isSuccess, isTrue);
    expect(result.message, contains('No log file'));
    expect(client.calls, ['text']);
  });

  test('sends only the summary when the log file is missing', () async {
    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: '${dir.path}/gone.txt')),
    );

    expect(result.isSuccess, isTrue);
    expect(client.calls, ['text']);
  });

  test('does not attach a log over the 16 MB limit', () async {
    final big = File('${dir.path}/big.txt');
    final sink = big.openSync(mode: FileMode.write);
    sink.truncateSync(WhatsAppLimits.maxDocumentBytes + 1);
    sink.closeSync();

    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: big.path)),
    );

    expect(result.isSuccess, isTrue);
    expect(result.message, contains('16 MB'));
    expect(client.calls, ['text']);
  });

  test('fails without touching the log when the summary fails', () async {
    client.textError = const WhatsAppApiException(
      message: 'WhatsApp did not accept the API key.',
      statusCode: 401,
    );

    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: logPath)),
    );

    expect(result.isFailed, isTrue);
    expect(result.message, contains('did not accept the API key'));
    expect(client.calls, ['text']);
  });

  test('reports a log that could not be uploaded', () async {
    client.uploadError = StateError('upload broke');

    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: logPath)),
    );

    expect(result.isFailed, isTrue);
    expect(result.message, contains('Summary sent'));
    expect(result.message, contains('upload broke'));
    expect(client.calls, ['text', 'upload']);
  });

  test('reports a log that could not be sent after upload', () async {
    client.documentError = StateError('send broke');

    final result = await handler.run(
      _context(snapshot: _snapshot(logFilePath: logPath)),
    );

    expect(result.isFailed, isTrue);
    expect(result.message, contains('send broke'));
    expect(client.calls, ['text', 'upload', 'document']);
  });
}
