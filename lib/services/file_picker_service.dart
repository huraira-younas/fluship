import 'package:file_picker/file_picker.dart';

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

    return result?.files.single.path;
  }
}
