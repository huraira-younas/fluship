String? driveMimeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.apk')) {
    return 'application/vnd.android.package-archive';
  }
  if (lower.endsWith('.aab') || lower.endsWith('.ipa')) {
    return 'application/octet-stream';
  }
  return null;
}
