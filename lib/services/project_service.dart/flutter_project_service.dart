import 'dart:io' show Directory, File;

import 'package:fluship/shared/models/app_info.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'pubspec_parser.dart';
import 'pubspec_info.dart';

class FlutterProjectException implements Exception {
  const FlutterProjectException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FlutterProjectService {
  const FlutterProjectService({PubspecParser? parser})
    : _parser = parser ?? const PubspecParser();

  final PubspecParser _parser;

  Future<PubspecInfo> readPubspec(String flutterProjectPath) async {
    final directory = Directory(flutterProjectPath);
    if (!await directory.exists()) {
      throw FlutterProjectException(
        'Flutter project path does not exist: $flutterProjectPath',
      );
    }

    final pubspecFile = File(p.join(flutterProjectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw FlutterProjectException(
        'pubspec.yaml not found in: $flutterProjectPath',
      );
    }

    final content = await pubspecFile.readAsString();

    try {
      return _parser.parse(content);
    } on FormatException catch (e) {
      throw FlutterProjectException(e.message);
    }
  }

  Future<AppInfoModel> extractAppInfo({
    required String flutterProjectPath,
    AppInfoModel? base,
  }) async {
    final pubspec = await readPubspec(flutterProjectPath);
    final current = base ?? const AppInfoModel();
    final appName = await _extractAppName(flutterProjectPath, pubspec);

    return current.copyWith(
      flutterProjectPath: flutterProjectPath,
      buildNumber: pubspec.buildNumber,
      version: pubspec.version,
      appName: appName,
    );
  }

  Future<void> bumpVersion({
    required String projectPath,
    required String buildNumber,
    required String version,
  }) async {
    final directory = Directory(projectPath);
    if (!await directory.exists()) {
      throw FlutterProjectException(
        'Flutter project path does not exist: $projectPath',
      );
    }

    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw FlutterProjectException('pubspec.yaml not found in: $projectPath');
    }

    final content = await pubspecFile.readAsString();

    late final String updated;
    try {
      updated = _parser.bumpVersionLine(
        buildNumber: buildNumber,
        version: version,
        content,
      );
    } on FormatException catch (error) {
      throw FlutterProjectException(error.message);
    }

    await pubspecFile.writeAsString(updated);
  }

  // 1. iOS → 2. Android → 3. pubspec name (formatted)
  Future<String> _extractAppName(
    String projectPath,
    PubspecInfo pubspec,
  ) async {
    return await _extractIosAppName(projectPath) ??
        await _extractAndroidAppName(projectPath) ??
        _formatPubspecName(pubspec.projectName);
  }

  Future<String?> _extractIosAppName(String projectPath) async {
    final plistFile = File(p.join(projectPath, 'ios', 'Runner', 'Info.plist'));
    if (!await plistFile.exists()) return null;

    try {
      final content = await plistFile.readAsString();

      String? findValue(String key) {
        final keyIndex = content.indexOf('<key>$key</key>');
        if (keyIndex == -1) return null;
        final after = content.indexOf('<string>', keyIndex);
        final end = content.indexOf('</string>', after);
        if (after == -1 || end == -1) return null;
        final value = content.substring(after + 8, end).trim();
        return value.isEmpty ? null : value;
      }

      return findValue('CFBundleDisplayName') ?? findValue('CFBundleName');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _extractAndroidAppName(String projectPath) async {
    final manifestFile = File(
      p.join(
        projectPath,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ),
    );
    if (!await manifestFile.exists()) return null;

    try {
      final content = await manifestFile.readAsString();
      final document = XmlDocument.parse(content);
      final application = document.findAllElements('application').firstOrNull;
      if (application == null) return null;

      final label = application.getAttribute('android:label');
      if (label == null || label.isEmpty) return null;

      if (label.startsWith('@string/')) {
        final key = label.substring('@string/'.length);
        return await _extractAndroidStringResource(projectPath, key);
      }

      return label;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _extractAndroidStringResource(
    String projectPath,
    String name,
  ) async {
    final stringsFile = File(
      p.join(
        projectPath,
        'android',
        'app',
        'src',
        'main',
        'res',
        'values',
        'strings.xml',
      ),
    );
    if (!await stringsFile.exists()) return null;

    try {
      final content = await stringsFile.readAsString();
      final document = XmlDocument.parse(content);
      for (final element in document.findAllElements('string')) {
        if (element.getAttribute('name') == name) {
          final text = element.innerText.trim();
          return text.isEmpty ? null : text;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _formatPubspecName(String name) => name
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}
