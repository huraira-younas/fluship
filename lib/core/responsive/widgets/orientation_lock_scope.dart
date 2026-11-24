import 'package:material_ui/material_ui.dart';

import '../models/responsive_info.dart';

class const OrientationLockScope({
  required final Widget child,
  required final AppOrientationLock lock,
  super.key,
}) extends StatefulWidget {
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
