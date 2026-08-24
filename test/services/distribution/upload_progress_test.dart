import 'package:fluship/services/distribution/upload/counted_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io' show Directory, File;

void main() {
  test('uploadPercent is null when total is unknown', () {
    expect(uploadPercent(50, 0), isNull);
    expect(uploadPercent(50, -1), isNull);
  });

  test('counted stream reports 50 of 100 bytes as 50 percent', () async {
    final dir = await Directory.systemTemp.createTemp('fluship_upload_');
    final file = File('${dir.path}/blob.bin');
    await file.writeAsBytes(List<int>.filled(100, 7));
    final reports = <(int, int, String)>[];

    try {
      final chunks = <int>[];
      await for (final chunk in countedFileStream(
        file,
        total: 100,
        fileName: 'blob.bin',
        onProgress: (bytes, total, name) {
          reports.add((bytes, total, name));
        },
      )) {
        chunks.addAll(chunk);
      }

      expect(chunks.length, 100);
      expect(reports, isNotEmpty);
      expect(reports.last.$1, 100);
      expect(reports.last.$2, 100);
      expect(uploadPercent(50, 100), 50);
      expect(
        formatUploadProgress(
          prefix: 'play',
          bytes: 50,
          total: 100,
          fileName: 'blob.bin',
        ),
        contains('50%'),
      );
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
