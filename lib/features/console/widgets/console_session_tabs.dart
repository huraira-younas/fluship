import 'package:fluship/features/console/models/console_session.dart';
import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'console_close_session.dart';
import '../bloc/console_bloc.dart';

const _animDuration = Duration(milliseconds: 200);
const _tabRadius = 8.0;

List<ConsoleSession> pipelineFirstSessions(List<ConsoleSession> sessions) {
  final pipeline = <ConsoleSession>[];
  final others = <ConsoleSession>[];
  for (final session in sessions) {
    if (isPipelineConsoleSession(session.id)) {
      pipeline.add(session);
    } else {
      others.add(session);
    }
  }
  return [...pipeline, ...others];
}

bool canCloseConsoleTab(int userSessionCount, ConsoleSession session) {
  if (isPipelineConsoleSession(session.id)) return true;
  return userSessionCount > 1;
}

class ConsoleSessionTabsData {
  const ConsoleSessionTabsData({
    required this.userSessionCount,
    required this.activeSessionId,
    required this.canAddSession,
    required this.sessions,
  });

  final List<ConsoleSession> sessions;
  final String? activeSessionId;
  final int userSessionCount;
  final bool canAddSession;
}

class ConsoleSessionTabs extends StatelessWidget {
  const ConsoleSessionTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConsoleBloc, ConsoleState, ConsoleSessionTabsData>(
      selector: (state) {
        final sessions = pipelineFirstSessions(state.sessions);
        final userSessionCount = state.sessions
            .where((session) => !isPipelineConsoleSession(session.id))
            .length;

        return ConsoleSessionTabsData(
          activeSessionId: state.activeSessionId,
          canAddSession: state.canAddSession,
          userSessionCount: userSessionCount,
          sessions: sessions,
        );
      },
      builder: (context, data) {
        final bloc = context.read<ConsoleBloc>();

        return _ConsoleSessionTabsBar(
          onAddSession: data.canAddSession
              ? () => bloc.add(const CreateSession())
              : null,
          onSelectSession: (sessionId) =>
              bloc.add(SelectSession(sessionId: sessionId)),
          onCloseSession: (session) => _closeSession(session, context, bloc),
          userSessionCount: data.userSessionCount,
          activeSessionId: data.activeSessionId,
          sessions: data.sessions,
        );
      },
    );
  }
}

Future<void> _closeSession(
  ConsoleSession session,
  BuildContext context,
  ConsoleBloc bloc,
) async {
  final confirmed = await confirmCloseSession(context, session);
  if (!confirmed || !context.mounted) return;

  if (isPipelineConsoleSession(session.id)) {
    bloc.add(ClosePipelineSession(sessionId: session.id));
  } else {
    bloc.add(CloseSession(sessionId: session.id));
  }
}

class _TabEntry {
  _TabEntry({required this.session, required this.controller})
    : key = GlobalKey();

  final AnimationController controller;
  ConsoleSession session;
  final GlobalKey key;
}

class _ConsoleSessionTabsBar extends StatefulWidget {
  const _ConsoleSessionTabsBar({
    required this.userSessionCount,
    required this.onSelectSession,
    required this.activeSessionId,
    required this.onCloseSession,
    required this.onAddSession,
    required this.sessions,
  });

  final Future<void> Function(ConsoleSession session) onCloseSession;
  final void Function(String sessionId) onSelectSession;
  final List<ConsoleSession> sessions;
  final VoidCallback? onAddSession;
  final String? activeSessionId;
  final int userSessionCount;

  @override
  State<_ConsoleSessionTabsBar> createState() => _ConsoleSessionTabsBarState();
}

class _ConsoleSessionTabsBarState extends State<_ConsoleSessionTabsBar>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  final List<_TabEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    for (final session in widget.sessions) {
      _entries.add(
        _TabEntry(
          session: session,
          controller: AnimationController(
            duration: _animDuration,
            vsync: this,
            value: 1.0,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActive(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant _ConsoleSessionTabsBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextIds = widget.sessions.map((s) => s.id).toSet();
    for (final entry in List.of(_entries)) {
      if (!nextIds.contains(entry.session.id)) {
        _animateRemove(entry);
      }
    }

    final currentIds = _entries.map((e) => e.session.id).toSet();
    for (final session in widget.sessions) {
      final existing = _entries
          .where((e) => e.session.id == session.id)
          .firstOrNull;
      if (existing != null) {
        existing.session = session;
      } else if (!currentIds.contains(session.id)) {
        final controller = AnimationController(
          duration: _animDuration,
          vsync: this,
        );
        _entries.add(_TabEntry(session: session, controller: controller));
        controller.forward();
      }
    }

    _reorderEntriesToMatchSessions();

    if (oldWidget.activeSessionId != widget.activeSessionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  void _reorderEntriesToMatchSessions() {
    final order = widget.sessions.map((session) => session.id).toList();
    _entries.sort((a, b) {
      final ai = order.indexOf(a.session.id);
      final bi = order.indexOf(b.session.id);
      return ai.compareTo(bi);
    });
  }

  void _animateRemove(_TabEntry entry) {
    entry.controller.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _entries.removeWhere((e) => e.session.id == entry.session.id);
      });
      entry.controller.dispose();
    });
  }

  void _scrollToActive({bool animate = true}) {
    final active = _entries
        .where((e) => e.session.id == widget.activeSessionId)
        .firstOrNull;
    if (active == null) return;

    final tabContext = active.key.currentContext;
    if (tabContext == null) return;

    final scrollable = Scrollable.maybeOf(tabContext);
    if (scrollable == null) return;

    final renderObject = tabContext.findRenderObject();
    if (renderObject == null) return;

    scrollable.position.ensureVisible(
      duration: animate ? _animDuration : Duration.zero,
      curve: Curves.easeInOut,
      alignment: 0.5,
      renderObject,
    );
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.consoleBg,
        border: Border(bottom: BorderSide(color: colors.consoleBorder)),
        borderRadius: .vertical(
          top: .circular(context.flushipTheme.radius.btn),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: .horizontal,
            controller: _scrollController,
            clipBehavior: .none,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                crossAxisAlignment: .end,
                children: [
                  ..._entries.map((entry) {
                    final session = entry.session;
                    final showClose = canCloseConsoleTab(
                      widget.userSessionCount,
                      session,
                    );

                    return _TabEnterExitTransition(
                      animation: entry.controller,
                      child: _SessionTab(
                        onClose: showClose
                            ? () => widget.onCloseSession(session)
                            : null,
                        onTap: () => widget.onSelectSession(session.id),
                        isSelected: session.id == widget.activeSessionId,
                        isRunning: session.isRunning,
                        title: session.title,
                        key: entry.key,
                      ),
                    );
                  }),
                  _AddTabButton(onTap: widget.onAddSession),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Enter / exit transition — slide-expand + fade (Chrome-like)
// ---------------------------------------------------------------------------

class _TabEnterExitTransition extends StatelessWidget {
  const _TabEnterExitTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        alignment: const Alignment(-1.0, 0.0),
        sizeFactor: curved,
        axis: .horizontal,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual session tab
// ---------------------------------------------------------------------------

class _SessionTab extends StatelessWidget {
  const _SessionTab({
    required this.isSelected,
    required this.isRunning,
    required this.onClose,
    required this.onTap,
    required this.title,
    super.key,
  });

  final VoidCallback? onClose;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isRunning;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;
    final canClose = onClose != null;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        final bgColor = Color.lerp(colors.consoleBg, colors.consoleInner, t)!;
        final labelColor = Color.lerp(colors.textDim, colors.text, t)!;
        final closeColor = Color.lerp(colors.muted, colors.textDim, t)!;

        // Selected tab drops 1px onto the output panel (Chrome-style merge).
        return Transform.translate(
          offset: Offset(0, t),
          child: GestureDetector(
            behavior: .opaque,
            onTap: onTap,
            child: Stack(
              clipBehavior: .none,
              children: [
                Container(
                  padding: .symmetric(
                    vertical: canClose ? 8 : 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const .vertical(top: .circular(_tabRadius)),
                    border: .all(color: colors.consoleBorder),
                    color: bgColor,
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
                            color: colors.accent,
                            shape: .circle,
                          ),
                        ),
                      AppText(
                        weight: t > 0.5 ? .w600 : .w500,
                        color: labelColor,
                        variant: .custom,
                        title,
                      ),
                      if (onClose != null)
                        GestureDetector(
                          behavior: .opaque,
                          onTap: onClose,
                          child: Icon(
                            color: closeColor,
                            Icons.close,
                            size: 16,
                          ).padOnly(t: 4, l: 4, b: 4),
                        ),
                    ],
                  ),
                ),
                if (t > 0)
                  Positioned(
                    left: 1,
                    right: 1,
                    bottom: 0,
                    height: 1,
                    child: ColoredBox(color: bgColor),
                  ),
              ],
            ),
          ),
        );
      },
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
      behavior: .opaque,
      onTap: onTap,
      child: Icon(
        Icons.add,
        size: 20,
        color: enabled
            ? colors.textDim
            : colors.textDim.withValues(alpha: 0.35),
      ).padSym(h: 12, v: 8),
    );
  }
}
