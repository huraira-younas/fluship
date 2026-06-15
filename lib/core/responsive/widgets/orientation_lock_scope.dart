import 'package:flutter/material.dart';

import '../models/responsive_info.dart';

class OrientationLockScope extends StatefulWidget {
  const OrientationLockScope({
    required this.child,
    required this.lock,
    super.key,
  });

  final AppOrientationLock lock;
  final Widget child;

  @override
  State<OrientationLockScope> createState() => _OrientationLockScopeState();
}

class _OrientationLockScopeState extends State<OrientationLockScope> {
  @override
  void initState() {
    super.initState();
    ResponsiveInfo.setOrientationLock(widget.lock);
  }

  @override
  void didUpdateWidget(OrientationLockScope oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lock != widget.lock) {
      ResponsiveInfo.setOrientationLock(widget.lock);
    }
  }

  @override
  void dispose() {
    ResponsiveInfo.clearOrientationLock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
