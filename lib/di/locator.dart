import 'package:fluship/services/console/contracts/console_session_pool.dart';
import 'package:fluship/services/console/runners/shell_runner_factory.dart';
import 'package:fluship/services/console/console_session_pool.dart';

import 'package:fluship/features/console/bloc/console_bloc.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class AppLocator {
  static void initialize() {
    getIt.registerSingleton(const FilePickerService());
    getIt.registerSingleton(ConfigBloc());

    getIt.registerSingleton(ShellRunnerFactory());
    getIt.registerSingleton<IConsoleSessionPool>(
      ConsoleSessionPool(factory: getIt<ShellRunnerFactory>()),
    );
    getIt.registerSingleton(ConsoleBloc(pool: getIt<IConsoleSessionPool>()));
  }
}
