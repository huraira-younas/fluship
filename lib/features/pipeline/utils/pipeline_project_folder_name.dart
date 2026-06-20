String sanitizeProjectFolderName(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'unknown';

  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
