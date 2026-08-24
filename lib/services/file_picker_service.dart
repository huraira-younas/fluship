import 'package:file_picker/file_picker.dart';
import 'dart:typed_data' show Uint8List;

class FilePickerService {
  const FilePickerService();

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
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
      dialogTitle: dialogTitle,
    );

    return result.single.path;
  }

  Future<String?> saveFile({
    List<String>? allowedExtensions,
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) {
    return FilePicker.saveFile(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
    ).then((value) => value?.toString());
  }
}
