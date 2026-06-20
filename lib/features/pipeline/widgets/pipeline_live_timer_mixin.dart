import 'package:flutter/material.dart';
import 'dart:async' show Timer;

mixin PipelineLiveTimerMixin<T extends StatefulWidget> on State<T> {
  Timer? _liveTimer;

  void syncLiveTimer({required bool isActive}) {
    _liveTimer?.cancel();
    if (!isActive) {
      _liveTimer = null;
      return;
    }

    _liveTimer = .periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }
}
