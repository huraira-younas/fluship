import 'dart:io';

import 'package:fluship/services/distribution/upload/counted_upload.dart';

import '../progress/progress_state.dart';

void reportCliUpload({
  required ProgressWriteGate gate,
  required String progressPath,
  required String prefix,
  required String id,
  required int bytes,
  required int total,
  required String fileName,
  int? fileIndex,
  int? fileCount,
}) {
  final percent = uploadPercent(bytes, total);
  if (!gate.allow(percent, DateTime.now())) return;
  final note = formatUploadProgress(
    prefix: prefix,
    bytes: bytes,
    total: total,
    fileName: fileName,
    fileIndex: fileIndex,
    fileCount: fileCount,
  );
  stdout.writeln(note);
  if (progressPath.isEmpty) return;
  patchUploadProgress(
    path: progressPath,
    upload: UploadProgressInfo(
      id: id,
      file: fileName,
      bytes: bytes,
      total: total,
      percent: percent,
      fileIndex: fileIndex,
      fileCount: fileCount,
    ),
    note: note,
  );
}
