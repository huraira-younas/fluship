import 'dart:io' show Platform;

import '../parsing/marker_shell_output_parser.dart';
import '../contracts/shell_runner_factory.dart';
import '../contracts/shell_output_parser.dart';
import '../contracts/shell_runner.dart';

import 'cmd_shell_runner.dart';
import 'sh_shell_runner.dart';

class ShellRunnerFactory({IShellOutputParser Function()? parserBuilder})
    implements IShellRunnerFactory {
  final IShellOutputParser Function() _parserBuilder =
      parserBuilder ?? MarkerShellOutputParser.new;

  @override
  IShellRunner build() {
    final parser = _parserBuilder();
    if (Platform.isWindows) return CmdShellRunner(parser: parser);
    return ShShellRunner(parser: parser);
  }
}
