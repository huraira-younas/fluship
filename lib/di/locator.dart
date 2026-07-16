import 'package:fluship/services/console/contracts/console_session_pool.dart';
import 'package:fluship/services/console/contracts/shell_runner_factory.dart';
import 'package:fluship/services/console/runners/shell_runner_factory.dart';
import 'package:fluship/services/console/console_session_pool.dart';

import 'package:fluship/features/file_manager/repository/file_manager_repository.dart';
import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:fluship/features/process_manager/bloc/process_manager_bloc.dart';
import 'package:fluship/features/pipeline/contracts/pipeline_config_source.dart';
import 'package:fluship/features/pipeline/contracts/pipeline_console_port.dart';
import 'package:fluship/features/file_manager/bloc/file_manager_bloc.dart';
import 'package:fluship/features/pipeline/bloc/pipeline_bloc.dart';
import 'package:fluship/services/distribution/distribution.dart';
import 'package:fluship/features/console/bloc/console_bloc.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class AppLocator {
  static void initialize() {
    getIt.registerSingleton(const FilePickerService());
    getIt.registerSingleton(ProjectProfilesStore());
    getIt.registerSingleton(
      FlushipWorkspacePaths(getIt<ProjectProfilesStore>()),
    );

    getIt.registerSingleton(ConfigBloc(getIt<ProjectProfilesStore>()));

    getIt.registerLazySingleton(
      () => FileManagerRepository(getIt<FlushipWorkspacePaths>()),
    );

    getIt.registerFactory(
      () => FileManagerBloc(repository: getIt<FileManagerRepository>()),
    );

    getIt.registerSingleton<IShellRunnerFactory>(ShellRunnerFactory());

    getIt.registerSingleton<IConsoleSessionPool>(
      ConsoleSessionPool(factory: getIt<IShellRunnerFactory>()),
    );

    getIt.registerSingleton(ConsoleBloc(pool: getIt<IConsoleSessionPool>()));

    getIt.registerLazySingleton(
      () => ProcessManagerBloc(sessionPool: getIt<IConsoleSessionPool>()),
    );

    getIt.registerSingleton(
      PipelineBloc(
        configSource: ConfigBlocPipelineSource(getIt<ConfigBloc>()),
        consolePort: ConsoleBlocPipelinePort(getIt<ConsoleBloc>()),
        FilePipelineLogWriter(getIt<FlushipWorkspacePaths>()),
        distributions: DistributionModule.createHandlerMap(),
      ),
    );
  }
}
