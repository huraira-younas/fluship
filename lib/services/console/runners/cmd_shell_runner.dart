import '../parsing/marker_shell_output_parser.dart';
import '../contracts/shell_output_parser.dart';

import 'base_shell_runner.dart';

final class CmdShellRunner extends BaseShellRunner {
  CmdShellRunner({IShellOutputParser? parser})
    : super(parser: parser ?? MarkerShellOutputParser());

  @override
  String get executable => 'cmd.exe';

  @override
  List<String> get startupArguments => const ['/Q', '/K'];

  @override
  String wrapCommand(String command) =>
      '@echo off\r\n'
      'echo __FLUSHIP_BEGIN__\r\n'
      '$command\r\n'
      'echo __FLUSHIP_END__:%ERRORLEVEL%\r\n'
      'echo __FLUSHIP_CWD__\r\n'
      'echo %CD%\r\n'
      'echo __FLUSHIP_CWD_END__';
}
