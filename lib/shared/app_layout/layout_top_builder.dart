import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/labels_builder.dart';
import 'package:fluship/core/app_theme/models/theme.dart';
import 'package:fluship/core/responsive/responsive.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

enum LayoutTabs {
  config(0),
  console(1),
  settings(2);

  const LayoutTabs(this.value);
  final int value;
}

class LayoutTopBuilder extends StatelessWidget {
  const LayoutTopBuilder({
    required this.onTabChanged,
    required this.selectedTab,
    required this.spacing,
    super.key,
  });

  final Function(LayoutTabs) onTabChanged;
  final LayoutTabs selectedTab;
  final ThemeSpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: spacing.lg,
      children: <Widget>[
        BlocSelector<ConfigBloc, ConfigState, AppInfoModel>(
          selector: (state) => state.appInfo,
          builder: (context, appInfo) {
            return ResponsiveBuilder(
              builder: (context, info) {
                final isMobile = info.isMobile;
                final header = <Widget>[
                  if (isMobile)
                    AppText.display(appInfo.appName ?? 'Fluship')
                  else
                    AppText.display(appInfo.appName ?? 'Fluship').expanded(),
                  AppButton.primary(
                    onPressed: () =>
                        getIt<ConfigBloc>().add(const SaveConfig()),
                    label: 'Run Pipeline',
                  ),
                ];

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: .stretch,
                    spacing: spacing.md,
                    children: header,
                  );
                }

                return Row(spacing: spacing.md, children: header);
              },
            );
          },
        ),
        LabelsBuilder(
          padding: .symmetric(horizontal: spacing.md),
          labels: LayoutTabs.values,
          onChange: onTabChanged,
          label: selectedTab,
        ),
      ],
    );
  }
}
