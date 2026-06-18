import '../models/shell_parse_result.dart';

abstract interface class IShellOutputParser {
  ShellParseResult feed(String chunk);
  ShellParseResult flush();
  void reset();
}
