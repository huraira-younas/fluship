import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/core/responsive/responsive_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_button.dart';
import 'package:fluship/shared/widgets/app_toast.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../sections/exports.dart';

const _sections = <_ProfileSection>[
  _ProfileSection(
    icon: Icons.file_download_outlined,
    child: ConfigBackup(),
    group: 'Project',
    label: 'Backup',
  ),
  _ProfileSection(
    icon: Icons.folder_outlined,
    child: ProjectPaths(),
    group: 'Project',
    label: 'Paths',
  ),
  _ProfileSection(
    icon: Icons.shop_outlined,
    child: GooglePlayConsole(),
    label: 'Play Store',
    group: 'Stores',
  ),
  _ProfileSection(
    icon: Icons.phone_iphone,
    child: IosCredentials(),
    label: 'App Store',
    group: 'Stores',
  ),
  _ProfileSection(
    icon: Icons.cloud_outlined,
    child: GoogleDrive(),
    group: 'Delivery',
    label: 'Drive',
  ),
  _ProfileSection(
    icon: Icons.chat_bubble_outline,
    child: SlackWebhook(),
    group: 'Delivery',
    label: 'Slack',
  ),
  _ProfileSection(
    icon: Icons.mail_outline,
    child: ReportsRecipients(),
    group: 'Delivery',
    label: 'Reports',
  ),
];

const _detailMaxWidth = 720.0;
const _railWidth = 240.0;
const _unsavedImportHint =
    'Imported settings are kept when you save this profile.';

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
  var _active = 0;

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
    final bloc = context.read<ConfigBloc>();
    final discardImport = bloc.state.pendingImport;
    if (discardImport) bloc.add(const LoadConfig());
    _requestPop(context, restorePrevious: !discardImport);
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
    final desktop = context.isDesktop;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      canPop: _canPop,
      child: Scaffold(
        appBar: desktop ? null : _mobileAppBar(context),
        body: BlocBuilder<ConfigBloc, ConfigState>(
          builder: (context, state) {
            final canSave = state.activeProject != null || state.pendingImport;
            if (desktop) {
              return _desktopBody(
                pendingImport: state.pendingImport,
                canSave: canSave,
                context,
              );
            }
            return _mobileBody(
              pendingImport: state.pendingImport,
              canSave: canSave,
              context,
            );
          },
        ),
      ),
    );
  }

  AppBar _mobileAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () => _close(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(widget.isAdding ? 'Add Profile' : 'Edit Profile'),
    );
  }

  Widget _mobileBody(
    BuildContext context, {
    required bool pendingImport,
    required bool canSave,
  }) {
    final spacing = context.flushipTheme.spacing;

    return SingleChildScrollView(
      padding: .all(spacing.lg),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: spacing.md,
        children: [
          if (pendingImport) const AppText.caption(_unsavedImportHint),
          for (final section in _sections) section.child,
          AppButton.primary(
            onPressed: canSave ? () => _save(context) : null,
            label: 'Save Profile',
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _desktopBody(
    BuildContext context, {
    required bool pendingImport,
    required bool canSave,
  }) {
    return Column(
      children: [
        _desktopHeader(context, pendingImport: pendingImport, canSave: canSave),
        Row(
          crossAxisAlignment: .stretch,
          children: [
            _ProfileSectionRail(
              onSelect: (index) => setState(() => _active = index),
              active: _active,
            ),
            _activeSection(context).expanded(),
          ],
        ).expanded(),
      ],
    );
  }

  Widget _desktopHeader(
    BuildContext context, {
    required bool pendingImport,
    required bool canSave,
  }) {
    final ft = context.flushipTheme;
    final spacing = ft.spacing;
    final title = widget.isAdding ? 'Add Profile' : 'Edit Profile';
    final subtitle = pendingImport
        ? _unsavedImportHint
        : widget.isAdding
        ? 'Set paths and credentials before the first pipeline run.'
        : 'Paths, store credentials, and delivery for this project.';

    final bar = Row(
      spacing: spacing.md,
      children: [
        AppButton.icon(
          onPressed: () => _close(context),
          leading: const Icon(Icons.arrow_back),
          semanticLabel: 'Back',
          variant: .secondary,
          tooltip: 'Back',
          size: .sm,
        ),
        Column(
          crossAxisAlignment: .start,
          children: [
            AppText.headline(title, maxLines: 1, overflow: .ellipsis),
            AppText.caption(subtitle, maxLines: 2, overflow: .ellipsis),
          ],
        ).expanded(),
        AppButton.primary(
          onPressed: canSave ? () => _save(context) : null,
          label: 'Save Profile',
        ),
      ],
    ).padSym(h: spacing.lg, v: spacing.md);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ft.colors.cardBorder)),
        color: ft.colors.cardBg,
      ),
      child: bar.safeArea(b: false, l: false, r: false),
    );
  }

  Widget _activeSection(BuildContext context) {
    final section = _sections[_active];
    final ft = context.flushipTheme;

    return SingleChildScrollView(
      key: PageStorageKey(section.label),
      padding: .all(ft.spacing.lg),
      child: Align(
        alignment: .topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _detailMaxWidth),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: ft.spacing.md,
            children: [
              _groupLabel(section.group).padOnly(l: ft.spacing.sm),
              section.child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionRail extends StatelessWidget {
  const _ProfileSectionRail({required this.onSelect, required this.active});

  final ValueChanged<int> onSelect;
  final int active;

  @override
  Widget build(BuildContext context) {
    final groups = _groupsIn(_allIndexes);
    final ft = context.flushipTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: ft.colors.codeBorder)),
        color: ft.colors.codeBg,
      ),
      width: _railWidth,
      child: ListView(
        padding: .all(ft.spacing.sm),
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            _groupLabel(groups[i].group).padOnly(
              t: i == 0 ? 0 : ft.spacing.md,
              l: ft.spacing.sm,
              b: ft.spacing.sm,
            ),
            for (final index in groups[i].indexes)
              _ProfileSectionTile(
                onTap: () => onSelect(index),
                selected: index == active,
                section: _sections[index],
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSectionTile extends StatelessWidget {
  const _ProfileSectionTile({
    required this.selected,
    required this.section,
    required this.onTap,
  });

  final _ProfileSection section;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final radius = BorderRadius.circular(ft.radius.input);
    final label = selected
        ? AppText.accent(section.label, maxLines: 1, overflow: .ellipsis)
        : AppText.body(section.label, maxLines: 1, overflow: .ellipsis);

    return Material(
      color: selected ? ft.colors.hover : ft.colors.codeBg,
      borderRadius: radius,
      child: InkWell(
        hoverColor: ft.colors.hover,
        borderRadius: radius,
        onTap: onTap,
        child: Row(
          spacing: ft.spacing.sm,
          children: [
            Container(
              decoration: BoxDecoration(
                color: selected ? ft.colors.accent : ft.colors.codeBg,
                borderRadius: .circular(ft.radius.input),
              ),
              height: 18,
              width: 3,
            ),
            Icon(
              color: selected ? ft.colors.accent : ft.colors.textDim,
              section.icon,
              size: 18,
            ),
            label.expanded(),
          ],
        ).padSym(h: ft.spacing.sm, v: ft.spacing.sm),
      ),
    );
  }
}

List<int> get _allIndexes => List.generate(_sections.length, (index) => index);

Widget _groupLabel(String label) {
  return AppText(label, variant: .secondary, weight: .w600, size: .caption);
}

List<({String group, List<int> indexes})> _groupsIn(List<int> indexes) {
  final groups = <({String group, List<int> indexes})>[];
  for (final index in indexes) {
    final name = _sections[index].group;
    if (groups.isEmpty || groups.last.group != name) {
      groups.add((group: name, indexes: [index]));
      continue;
    }
    groups.last.indexes.add(index);
  }
  return groups;
}

class _ProfileSection {
  const _ProfileSection({
    required this.group,
    required this.label,
    required this.child,
    required this.icon,
  });

  final IconData icon;
  final String group;
  final String label;
  final Widget child;
}
