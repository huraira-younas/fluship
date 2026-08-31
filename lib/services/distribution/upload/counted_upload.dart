import 'dart:io' show File;

typedef UploadByteProgress =
    void Function(int bytes, int total, String fileName);

int? uploadPercent(int bytes, int total) {
  if (total <= 0) return null;
  final raw = (bytes * 100) ~/ total;
  if (raw < 0) return 0;
  if (raw > 100) return 100;
  return raw;
}

String formatMegabytes(int bytes) {
  return (bytes / (1024 * 1024)).toStringAsFixed(1);
}

Stream<List<int>> countedFileStream(
  File file, {
  UploadByteProgress? onProgress,
  required String fileName,
  required int total,
}) async* {
  var sent = 0;
  await for (final chunk in file.openRead()) {
    sent += chunk.length;
    onProgress?.call(sent, total, fileName);
    yield chunk;
  }
}
