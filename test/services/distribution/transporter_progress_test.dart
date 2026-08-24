import 'package:fluship/services/distribution/app_store/transporter_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a transporter percent and ignores other lines', () {
    expect(parseTransporterPercent('Uploading 12.4% complete'), 12);
    expect(parseTransporterPercent('PKG 100%'), 100);
    expect(parseTransporterPercent('starting upload'), isNull);
    expect(parseTransporterPercent('120%'), isNull);
  });
}
