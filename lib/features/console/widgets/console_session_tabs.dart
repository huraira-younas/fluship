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

        return _ConsoleSessionTabsBar(
          onAddSession: data.canAddSession
              ? () => bloc.add(const CreateSession())
              : null,
          onSelectSession: (sessionId) =>
              bloc.add(SelectSession(sessionId: sessionId)),
          onCloseSession: (session) => _closeSession(context, bloc, session),
          activeSessionId: data.activeSessionId,
          canClose: data.sessions.length > 1,
          sessions: data.sessions,
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

class _ConsoleSessionTabsBar extends StatefulWidget {
  const _ConsoleSessionTabsBar({
    required this.onCloseSession,
    required this.onSelectSession,
    required this.activeSessionId,
    required this.onAddSession,
    required this.canClose,
    required this.sessions,
  });

  final Future<void> Function(ConsoleSession session) onCloseSession;
  final void Function(String sessionId) onSelectSession;
  final VoidCallback? onAddSession;
  final List<ConsoleSession> sessions;
  final String? activeSessionId;
  final bool canClose;

  @override
  State<_ConsoleSessionTabsBar> createState() => _ConsoleSessionTabsBarState();
}

class _ConsoleSessionTabsBarState extends State<_ConsoleSessionTabsBar> {
  static const _animationDuration = Duration(milliseconds: 300);

  late final ScrollController _scrollController;
  late List<GlobalKey> _keys;

  final _stackKey = GlobalKey();

  bool _indicatorReady = false;
  double _indicatorWidth = 0;
  double _indicatorLeft = 0;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _updateKeys();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicator();
      _scrollToActive(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant _ConsoleSessionTabsBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final sessionsChanged = _sessionsChanged(
      oldWidget.sessions,
      widget.sessions,
    );
    final layoutChanged = _sessionsLayoutChanged(
      oldWidget.sessions,
      widget.sessions,
    );
    final selectionChanged =
        oldWidget.activeSessionId != widget.activeSessionId;

    if (sessionsChanged) {
      _updateKeys();
      _indicatorReady = false;
    }

    if (selectionChanged) {
      _scrollToActive();
    }

    if (sessionsChanged || layoutChanged || selectionChanged) {
      _scheduleIndicatorUpdate();
    }
  }

  bool _sessionsChanged(
    List<ConsoleSession> previous,
    List<ConsoleSession> current,
  ) {
    if (previous.length != current.length) return true;

    for (var i = 0; i < previous.length; i++) {
      if (previous[i].id != current[i].id) return true;
    }

    return false;
  }

  bool _sessionsLayoutChanged(
    List<ConsoleSession> previous,
    List<ConsoleSession> current,
  ) {
    if (previous.length != current.length) return true;

    for (var i = 0; i < previous.length; i++) {
      final oldSession = previous[i];
      final newSession = current[i];

      if (oldSession.id != newSession.id ||
          oldSession.title != newSession.title ||
          oldSession.isRunning != newSession.isRunning) {
        return true;
      }
    }

    return false;
  }

  void _updateKeys() {
    _keys = List.generate(widget.sessions.length, (_) => GlobalKey());
  }

  void _scheduleIndicatorUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateIndicator();
    });
  }

  void _updateIndicator() {
    final activeIndex = widget.sessions.indexWhere(
      (session) => session.id == widget.activeSessionId,
    );
    if (activeIndex == -1) {
      if (_indicatorReady) {
        setState(() => _indicatorReady = false);
      }
      return;
    }

    final tabContext = _keys[activeIndex].currentContext;
    final stackContext = _stackKey.currentContext;
    if (tabContext == null || stackContext == null) return;

    final tabBox = tabContext.findRenderObject() as RenderBox?;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (tabBox == null || stackBox == null || !tabBox.hasSize) return;

    final stackOrigin = stackBox.localToGlobal(Offset.zero);
    final tabOrigin = tabBox.localToGlobal(Offset.zero);
    final left = tabOrigin.dx - stackOrigin.dx;
    final width = tabBox.size.width;

    if (left == _indicatorLeft && width == _indicatorWidth && _indicatorReady) {
      return;
    }

    setState(() {
      _indicatorWidth = width;
      _indicatorReady = true;
      _indicatorLeft = left;
    });
  }

  void _scrollToActive({bool animate = true}) {
    final activeIndex = widget.sessions.indexWhere(
      (session) => session.id == widget.activeSessionId,
    );
    if (activeIndex == -1) return;

    final tabContext = _keys[activeIndex].currentContext;
    if (tabContext == null) return;

    final scrollable = Scrollable.maybeOf(tabContext);
    if (scrollable == null) return;

    final renderObject = tabContext.findRenderObject();
    if (renderObject == null) return;

    scrollable.position.ensureVisible(
      duration: animate ? _animationDuration : Duration.zero,
      curve: Curves.easeInOut,
      alignment: 0.5,
      renderObject,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final colors = ft.colors;

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      controller: _scrollController,
      clipBehavior: .none,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: .circular(ft.radius.btn + 15),
          border: .all(color: colors.cardBorder),
          color: colors.consoleBg,
        ),
        padding: const .all(4),
        child: LayoutBuilder(
          builder: (context, _) {
            _scheduleIndicatorUpdate();

            return Stack(
              key: _stackKey,
              clipBehavior: .none,
              children: [
                if (_indicatorReady)
                  AnimatedPositioned(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    width: _indicatorWidth,
                    left: _indicatorLeft,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: .circular(20),
                        color: colors.text,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    ...widget.sessions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final session = entry.value;
                      final active = session.id == widget.activeSessionId;

                      return _SessionTab(
                        onClose: widget.canClose
                            ? () => widget.onCloseSession(session)
                            : null,
                        onTap: () => widget.onSelectSession(session.id),
                        isRunning: session.isRunning,
                        isSelected: active,
                        title: session.title,
                        key: _keys[index],
                      );
                    }),
                    _AddTabButton(onTap: widget.onAddSession),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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

    return GestureDetector(
      onTap: onTap,
      behavior: .opaque,
      child: Padding(
        padding: const .symmetric(horizontal: 16, vertical: 8),
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
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 8),
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
