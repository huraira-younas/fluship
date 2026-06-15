import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/string_extensions.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class LabelsBuilder<T> extends StatefulWidget {
  const LabelsBuilder({
    required this.onChange,
    required this.padding,
    required this.labels,
    required this.label,
    super.key,
  });

  final void Function(T label) onChange;
  final EdgeInsets padding;
  final List<T> labels;
  final T label;

  @override
  State<LabelsBuilder<T>> createState() => _LabelsBuilderState<T>();
}

class _LabelsBuilderState<T> extends State<LabelsBuilder<T>> {
  late final ScrollController _scrollController;
  late List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _updateKeys();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToActive(animate: false),
    );
  }

  @override
  void didUpdateWidget(covariant LabelsBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      _updateKeys();
    }

    if (oldWidget.label != widget.label) {
      _scrollToActive();
    }
  }

  void _updateKeys() {
    _keys = List.generate(widget.labels.length, (index) => GlobalKey());
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
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
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
      controller: _scrollController,
      clipBehavior: Clip.none,
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: .circular(radius.btn + 15),
          border: .all(color: colors.cardBorder),
          color: colors.cardBg,
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
        child: Row(
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
              onTap: () => widget.onChange(value),
              title: text.capitalize,
              isSelected: active,
              key: _keys[idx],
            );
          }),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.isSelected,
    required this.onTap,
    required this.title,
    super.key,
  });
  final VoidCallback onTap;
  final bool isSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.flushipTheme.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: .opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const .symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.text : Colors.transparent,
          borderRadius: .circular(20),
        ),
        child: AppText.custom(
          color: isSelected ? colors.bg : colors.textDim,
          weight: isSelected ? .w700 : .w500,
          title,
        ),
      ),
    );
  }
}
