import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locator.dart';

class AppBlocProviders {
  static List<BlocProvider> get providers {
    return [
      BlocProvider<ConfigBloc>(
        create: (_) => getIt<ConfigBloc>()..add(const LoadConfig()),
        lazy: false,
      ),
    ];
  }
}
