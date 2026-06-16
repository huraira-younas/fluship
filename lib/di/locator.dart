import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class AppLocator {
  static void initialize() {
    getIt.registerSingleton(ConfigBloc());
  }
}
