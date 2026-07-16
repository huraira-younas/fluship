import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../sections/exports.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({
    required this.isAdding,
    this.previousProject,
    super.key,
  });

  final String? previousProject;
  final bool isAdding;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  var _canPop = false;

  void _save(BuildContext context) {
    context.read<ConfigBloc>().add(
      SaveConfig(
        onSuccess: (_) {
          AppToast.success('Profile saved successfully');
          if (!context.mounted) return;
          _requestPop(context, restorePrevious: false);
        },
        onError: (error) => AppToast.error(error.message),
      ),
    );
  }

  void _close(BuildContext context) {
    _requestPop(context, restorePrevious: true);
  }

  void _requestPop(BuildContext context, {required bool restorePrevious}) {
    final bloc = context.read<ConfigBloc>();
    if (restorePrevious &&
        widget.isAdding &&
        bloc.state.activeProject == null &&
        widget.previousProject != null) {
      bloc.add(SwitchProjectProfile(projectName: widget.previousProject!));
    }
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.flushipTheme.spacing;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      canPop: _canPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => _close(context),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(widget.isAdding ? 'Add Profile' : 'Edit Profile'),
        ),
        body: BlocBuilder<ConfigBloc, ConfigState>(
          builder: (context, state) => SingleChildScrollView(
            padding: .all(spacing.lg),
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: spacing.md,
              children: [
                const ConfigBackup(),
                const ProjectPaths(),
                const GooglePlayConsole(),
                const IosCredentials(),
                const GoogleDrive(),
                const SlackWebhook(),
                const ReportsRecipients(),
                AppButton.primary(
                  isExpanded: true,
                  onPressed: state.activeProject == null
                      ? null
                      : () => _save(context),
                  label: 'Save Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
