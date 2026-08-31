import 'package:fluship/services/distribution/app_store/transporter_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a transporter percent and ignores other lines', () {
    expect(parseTransporterPercent('Uploading 12.4% complete'), 12);
    expect(parseTransporterPercent('PKG 100%'), 100);
    expect(parseTransporterPercent('starting upload'), isNull);
    expect(parseTransporterPercent('120%'), isNull);
  });

  test('treats debug transporter chatter as noise', () {
    expect(isTransporterNoise('DBG-X: packet 12'), isTrue);
    expect(isTransporterNoise('[DBG] verbose'), isTrue);
    expect(isTransporterNoise(''), isTrue);
    expect(isTransporterNoise('Uploading 12% complete'), isFalse);
  });

  test('logs only useful transporter lines', () {
    expect(isTransporterLogLine('DBG-X: packet 12'), isFalse);
    expect(isTransporterLogLine('Uploading 12% complete'), isFalse);
    expect(isTransporterLogLine('ERROR ITMS-9000: Invalid bundle'), isTrue);
    expect(isTransporterLogLine('Unable to authenticate'), isTrue);
  });
}
