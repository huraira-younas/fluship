import 'pipeline_upload_progress.dart';

class UploadProgressGate {
  int? _lastPercent;
  String? _lastKey;

  bool allow(PipelineUploadProgress progress) {
    final key = '${progress.fileName}\u0000${progress.fileIndex}';
    if (progress.percent == _lastPercent && key == _lastKey) {
      return false;
    }
    _lastPercent = progress.percent;
    _lastKey = key;
    return true;
  }

  void reset() {
    _lastPercent = null;
    _lastKey = null;
  }
}
