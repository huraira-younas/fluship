import '../parsing/marker_shell_output_parser.dart';
import '../contracts/shell_output_parser.dart';

import 'base_shell_runner.dart';

final class ShShellRunner extends BaseShellRunner {
  ShShellRunner({IShellOutputParser? parser})
    : super(parser: parser ?? MarkerShellOutputParser());

  @override
  String get executable => 'sh';

  @override
  List<String> get startupArguments => const [];

  @override
  String wrapCommand(String command) =>
      'echo __FLUSHIP_BEGIN__\n'
      '$command\n'
      r'echo __FLUSHIP_END__:$?'
      '\n'
      'echo __FLUSHIP_CWD__\n'
      'pwd\n'
      'echo __FLUSHIP_CWD_END__';
}
