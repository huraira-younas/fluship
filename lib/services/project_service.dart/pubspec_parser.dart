import 'pubspec_info.dart';

class PubspecParser {
  const PubspecParser();

  PubspecInfo parse(String content) {
    String? projectName;
    String? versionLine;

    for (final raw in content.split('\n')) {
      final line = _stripInlineComment(raw).trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('name:')) {
        projectName = _stripQuotes(line.substring(5).trim());
      } else if (line.startsWith('version:')) {
        versionLine = _stripQuotes(line.substring(8).trim());
      }
    }

    if (projectName == null || projectName.isEmpty) {
      throw const FormatException(
        'pubspec.yaml is missing a valid name field.',
      );
    }

    if (versionLine == null || versionLine.isEmpty) {
      throw const FormatException(
        'pubspec.yaml is missing a valid version field.',
      );
    }

    final parts = versionLine.split('+');
    final version = parts.first.trim();
    final buildNumber = parts.length > 1 ? parts[1].trim() : null;

    return PubspecInfo(
      buildNumber: buildNumber == null || buildNumber.isEmpty
          ? null
          : buildNumber,
      projectName: projectName,
      version: version,
    );
  }

  static String _stripInlineComment(String line) {
    final index = line.indexOf('#');
    return index == -1 ? line : line.substring(0, index);
  }

  static String _stripQuotes(String value) {
    if (value.length >= 2) {
      final quote = value[0];
      if ((quote == '"' || quote == "'") && value.endsWith(quote)) {
        return value.substring(1, value.length - 1);
      }
    }
    return value;
  }
}
