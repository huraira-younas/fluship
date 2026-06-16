import 'package:fluship/shared/extensions/context_extensions.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/custom_label_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/config_bloc.dart';
import '../sections/exports.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = context.screenHeight * 0.29;
    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          ).padOnly(t: pad * 1.35);
        }

        if (state.error != null) {
          return CustomLabelWidget(
            onTap: () => context.read<ConfigBloc>().add(const LoadConfig()),
            text: state.error!.message,
            icon: Icons.error,
            btnText: "Retry",
            title: "Error",
          ).padOnly(t: pad);
        }

        final fp = state.appInfo.flutterProjectPath;
        if (fp == null || fp.isEmpty) {
          return CustomLabelWidget(
            onTap: () => context.read<ConfigBloc>().add(const LoadConfig()),
            text: "No Flutter project path found",
            btnText: "Select Project",
            icon: Icons.folder,
            title: "Error",
          ).padOnly(t: pad);
        }

        return const Column(
          spacing: 20,
          children: <Widget>[
            BuildConfig(),
            PreGit(),
            CommonCmd(),
            AndroidConfig(),
            IosConfig(),
            PostGit(),
          ],
        );
      },
    );
  }
}
