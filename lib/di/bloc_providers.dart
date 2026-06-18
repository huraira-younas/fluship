import 'package:fluship/features/pipeline/bloc/pipeline_bloc.dart';
import 'package:fluship/features/console/bloc/console_bloc.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/core/app_theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locator.dart';

class AppBlocProviders {
  static List<BlocProvider> get providers {
    return [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(), lazy: false),
      BlocProvider<ConfigBloc>(
        create: (_) => getIt<ConfigBloc>()..add(const LoadConfig()),
        lazy: false,
      ),
      BlocProvider<ConsoleBloc>(
        create: (_) => getIt<ConsoleBloc>(),
        lazy: false,
      ),
      BlocProvider<PipelineBloc>(
        create: (_) => getIt<PipelineBloc>(),
        lazy: false,
      ),
    ];
  }
}
