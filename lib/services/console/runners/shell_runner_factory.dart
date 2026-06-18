import 'dart:io' show Platform;

import '../parsing/marker_shell_output_parser.dart';
import '../contracts/shell_runner_factory.dart';
import '../contracts/shell_output_parser.dart';
import '../contracts/shell_runner.dart';

import 'cmd_shell_runner.dart';
import 'sh_shell_runner.dart';

class ShellRunnerFactory implements IShellRunnerFactory {
  ShellRunnerFactory({IShellOutputParser Function()? parserBuilder})
    : _parserBuilder = parserBuilder ?? MarkerShellOutputParser.new;

  final IShellOutputParser Function() _parserBuilder;

  @override
  IShellRunner build() {
    final parser = _parserBuilder();
    if (Platform.isWindows) return CmdShellRunner(parser: parser);
    return ShShellRunner(parser: parser);
  }
}
