import 'package:fluship/features/console/models/console_session.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'console_close_session.dart';
import '../bloc/console_bloc.dart';

class ConsoleSessionTabsData {
  const ConsoleSessionTabsData({
    required this.activeSessionId,
    required this.canAddSession,
    required this.sessions,
  });

  final List<ConsoleSession> sessions;
  final String? activeSessionId;
  final bool canAddSession;
}

class ConsoleSessionTabs extends StatelessWidget {
  const ConsoleSessionTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, ConsoleSessionTabsData>(
      selector: (state) => ConsoleSessionTabsData(
        activeSessionId: state.activeSessionId,
        canAddSession: state.canAddSession,
        sessions: state.sessions,
      ),
      builder: (context, data) {
        final bloc = context.read<ConsoleBloc>();
        final ft = context.flushipTheme;
        final colors = ft.colors;

        return SingleChildScrollView(
          scrollDirection: .horizontal,
          clipBehavior: .none,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: .circular(ft.radius.btn + 15),
              border: .all(color: colors.cardBorder),
              color: colors.consoleBg,
            ),
            padding: const .all(4),
            child: Row(
              mainAxisSize: .min,
              spacing: 4,
              children: [
                ...data.sessions.map((session) {
                  final active = session.id == data.activeSessionId;
                  return _SessionTab(
                    onClose: data.sessions.length > 1
                        ? () => _closeSession(context, bloc, session)
                        : null,
                    onTap: () => bloc.add(SelectSession(sessionId: session.id)),
                    isRunning: session.isRunning,
                    title: session.title,
                    isSelected: active,
                  );
                }),
                _AddTabButton(
                  onTap: data.canAddSession
                      ? () => bloc.add(const CreateSession())
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _closeSession(
  BuildContext context,
  ConsoleBloc bloc,
  ConsoleSession session,
) async {
  final confirmed = await confirmCloseSession(context, session);
  if (!confirmed || !context.mounted) return;
  bloc.add(CloseSession(sessionId: session.id));
}

class _SessionTab extends StatelessWidget {
  const _SessionTab({
    required this.isSelected,
    required this.isRunning,
    required this.onClose,
    required this.onTap,
    required this.title,
  });

  final VoidCallback? onClose;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isRunning;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: .opaque,
      child: AnimatedContainer(
        padding: const .symmetric(horizontal: 16, vertical: 8),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? colors.text : Colors.transparent,
          borderRadius: .circular(20),
        ),
        child: Row(
          mainAxisSize: .min,
          spacing: 6,
          children: [
            if (isRunning)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? colors.bg : colors.accent,
                  shape: .circle,
                ),
              ),
            AppText(
              title,
              color: isSelected ? colors.bg : colors.textDim,
              variant: isSelected ? .custom : .dim,
              weight: isSelected ? .w700 : .w500,
            ),
            if (onClose != null)
              GestureDetector(
                behavior: .opaque,
                onTap: onClose,
                child: Padding(
                  padding: const .all(4),
                  child: Icon(
                    color: isSelected ? colors.bg : colors.textDim,
                    Icons.close,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddTabButton extends StatelessWidget {
  const _AddTabButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      behavior: .opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const .symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: .circular(20),
          color: Colors.transparent,
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: enabled
              ? colors.textDim
              : colors.textDim.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
