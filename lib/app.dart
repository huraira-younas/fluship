import 'package:fluship/core/responsive/responsive.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fluship/core/navigator.dart';

import 'shared/app_layout/app_layout.dart';
import 'core/app_theme/theme_cubit.dart';
import 'di/bloc_providers.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: AppBlocProviders.providers,
    child: BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) => ToastificationWrapper(
        child: OrientationLockScope(
          lock: .portrait,
          child: MaterialApp(
            builder: (context, child) =>
                // ignore: deprecated_member_use
                MaterialUiCompatibilityBridge(
                  child: GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: child,
                  ),
                ),
            debugShowCheckedModeBanner: false,
            darkTheme: state.darkThemeData,
            navigatorKey: appNavigatorKey,
            theme: state.lightThemeData,
            home: const LayoutScreen(),
            themeMode: state.mode,
            title: 'Fluship',
          ),
        ),
      ),
    ),
  );
}
