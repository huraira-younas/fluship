import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/string_extensions.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class AppTabs<T> extends StatefulWidget {
  const AppTabs({
    this.scrollPadding = .zero,
    this.variant = .custom,
    required this.onChange,
    this.disabled = false,
    required this.labels,
    required this.label,
    this.contentPadding,
    super.key,
  });

  final void Function(T label) onChange;
  final EdgeInsets? contentPadding;
  final EdgeInsets? scrollPadding;
  final AppTextVariant variant;
  final List<T> labels;
  final bool disabled;
  final T label;

  @override
  State<AppTabs<T>> createState() => _AppTabsState<T>();
}

class _AppTabsState<T> extends State<AppTabs<T>> {
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
  void didUpdateWidget(covariant AppTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final labelsChanged = oldWidget.labels.length != widget.labels.length;
    final selectionChanged = oldWidget.label != widget.label;
    final layoutChanged =
        oldWidget.contentPadding != widget.contentPadding ||
        oldWidget.disabled != widget.disabled;

    if (labelsChanged) {
      _updateKeys();
      _indicatorReady = false;
    }

    if (selectionChanged) {
      _scrollToActive();
    }

    if (labelsChanged || selectionChanged || layoutChanged) {
      _scheduleIndicatorUpdate();
    }
  }

  void _updateKeys() {
    _keys = List.generate(widget.labels.length, (index) => GlobalKey());
  }

  void _scheduleIndicatorUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateIndicator();
    });
  }

  void _updateIndicator() {
    if (widget.disabled) {
      if (_indicatorReady) {
        setState(() => _indicatorReady = false);
      }
      return;
    }

    final index = widget.labels.indexOf(widget.label);
    if (index == -1) return;

    final tabContext = _keys[index].currentContext;
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
    final index = widget.labels.indexOf(widget.label);
    if (index == -1) return;

    final tabContext = _keys[index].currentContext;
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
    final theme = context.flushipTheme;
    final colors = theme.colors;
    final radius = theme.radius;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: widget.scrollPadding,
      controller: _scrollController,
      clipBehavior: Clip.none,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: .circular(radius.btn + 15),
          border: .all(color: colors.cardBorder),
          color: colors.consoleBg,
          boxShadow: [
            BoxShadow(
              color: colors.text.withValues(alpha: 0.06),
              offset: const Offset(0, 1),
              spreadRadius: 1,
              blurRadius: 1,
            ),
          ],
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
                  children: List.generate(widget.labels.length, (idx) {
                    final value = widget.labels[idx];
                    final active = widget.label == value;

                    final text = value is Enum
                        ? value.name
                        : value is String
                        ? value
                        : value.toString();

                    return _TabButton(
                      onTap: widget.disabled
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              widget.onChange(value);
                            },
                      contentPadding: widget.contentPadding,
                      variant: widget.variant,
                      title: text.capitalize,
                      isSelected: active,
                      key: _keys[idx],
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.contentPadding,
    required this.isSelected,
    required this.variant,
    required this.title,
    this.onTap,
    super.key,
  });

  final EdgeInsets? contentPadding;
  final AppTextVariant variant;
  final VoidCallback? onTap;
  final bool isSelected;
  final String title;

  bool get _disabled => onTap == null;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: .opaque,
      child: Container(
        padding:
            contentPadding ?? const .symmetric(horizontal: 24, vertical: 8),
        child: AppText(
          variant: variant,
          color: _disabled
              ? colors.textDim.withValues(alpha: 0.4)
              : isSelected
              ? colors.bg
              : colors.textDim,
          weight: isSelected && !_disabled ? .w700 : .w500,
          title,
        ),
      ),
    );
  }
}
