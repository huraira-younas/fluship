import 'package:file_picker/file_picker.dart';

import 'dart:typed_data' show Uint8List;

class const FilePickerService() {
  Future<String?> pickDirectory({String? dialogTitle}) {
    return FilePicker.getDirectoryPath(
      dialogTitle: dialogTitle ?? 'Select folder',
    );
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
