import 'package:fluship/core/responsive/responsive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'shared/app_layout/app_layout.dart';
import 'core/app_theme/theme_cubit.dart';
import 'di/bloc_providers.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: AppBlocProviders.providers,
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return OrientationLockScope(
            lock: .portrait,
            child: MaterialApp(
              builder: (context, child) => GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: child,
              ),
              debugShowCheckedModeBanner: false,
              home: const LayoutScreen(),
              theme: state.themeData,
              title: 'Fluship',
            ),
          );
        },
      ),
    );
  }
}
