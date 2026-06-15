import 'package:intl/intl.dart';

extension StringX on String {
  bool get isNullOrEmpty => trim().isEmpty;
  String get capitalize {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }

  String get normalize => split("\n").join(" ").trim();

  String get formatTime {
    if (isEmpty) return this;
    try {
      final parts = split(':');
      if (parts.length < 2) return this;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dateTime = DateTime(2024, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dateTime);
    } catch (_) {
      return this;
    }
  }
}
