import 'package:fluship/services/process/process.dart';
import 'package:flutter_test/flutter_test.dart';

RawProcessRow _row(int pid, int ppid) =>
    RawProcessRow(command: 'cmd $pid', ppid: ppid, pid: pid);

void main() {
  group('ProcessTreeKiller.descendantsOf', () {
    test('returns nested children, deepest first', () {
      final rows = [
        _row(10, 1), // shell
        _row(20, 10), // flutter
        _row(30, 20), // dart
        _row(40, 30), // gradle client
        _row(50, 10), // second child of the shell
      ];

      final result = ProcessTreeKiller.descendantsOf(rows, 10);

      expect(result, unorderedEquals([20, 30, 40, 50]));
      expect(result.indexOf(40), lessThan(result.indexOf(30)));
      expect(result.indexOf(30), lessThan(result.indexOf(20)));
      expect(result, isNot(contains(10)));
    });

    test('leaves unrelated processes alone', () {
      final rows = [_row(10, 1), _row(20, 10), _row(99, 1), _row(100, 99)];

      expect(ProcessTreeKiller.descendantsOf(rows, 10), [20]);
    });

    test('returns nothing when the root is missing or has no children', () {
      final rows = [_row(10, 1), _row(20, 1)];

      expect(ProcessTreeKiller.descendantsOf(rows, 10), isEmpty);
      expect(ProcessTreeKiller.descendantsOf(rows, 777), isEmpty);
    });

    test('does not loop on a pid cycle', () {
      final rows = [_row(10, 20), _row(20, 10)];

      expect(ProcessTreeKiller.descendantsOf(rows, 10), [20]);
    });
  });
}
