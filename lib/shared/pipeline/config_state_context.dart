import 'package:fluship/features/config/bloc/config_bloc.dart';

extension ConfigStateContext on ConfigState {
  String get projectRoot => appInfo.flutterProjectPath ?? '';
  String get buildNumber => appInfo.buildNumber ?? '';
  String get version => appInfo.version ?? '';

  String get gitBranch =>
      preGit.targetBranch ?? postGit.targetBranch ?? 'master';

  String resolveCommitMessage(String? template, {required String fallback}) =>
      (template ?? fallback).replaceAll('{version}', version);
}
