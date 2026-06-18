import 'package:fluship/features/console/bloc/console_bloc.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/services/file_picker_service.dart';
import 'package:fluship/services/console_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class AppLocator {
  static void initialize() {
    getIt.registerSingleton(const FilePickerService());
    getIt.registerSingleton(ConsoleService());
    getIt.registerSingleton(ConsoleBloc());
    getIt.registerSingleton(ConfigBloc());
  }
}
