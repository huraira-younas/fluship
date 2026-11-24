import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'dart:typed_data' show Uint8List;

class const FilePickerService() {
  Future<String?> pickDirectory({String? dialogTitle}) async {
    final uri = await FilePicker.pickDirectory(
      dialogTitle: dialogTitle ?? 'Select folder',
    );

    // The picker returns a directory URI, so its path ends with a separator.
    // Normalize drops it, to keep the plain path the app has always stored.
    return uri == null ? null : p.normalize(uri.toFilePath());
  }

  Future<String?> pickFile({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    final result = await FilePicker.pickFiles(
      type: allowedExtensions != null ? .custom : .any,
      allowedExtensions: allowedExtensions,
      dialogTitle: dialogTitle,
    );

    return result.single.path;
  }

  Future<String?> saveFile({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) {
    return FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
    ).then((value) => value?.toString());
  }
}
