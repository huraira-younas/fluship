import 'package:fluship/services/process/process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const classifier = ProcessClassifier();
  const project = '/Users/dev/my_app';

  group('ProcessClassifier', () {
    test('marks child of tracked shell as active', () {
      final rows = classifier.classify(
        trackedShellPids: const {'_pipeline_console': 100},
        showAllChildren: false,
        projectRoot: project,
        selfPid: 1,
        rows: const [
          RawProcessRow(command: 'sh', ppid: 1, pid: 100),
          RawProcessRow(
            command: 'flutter build apk --release',
            ppid: 100,
            pid: 200,
          ),
        ],
      );

      expect(rows, hasLength(1));
      expect(rows.single.kind, ProcessKind.active);
      expect(rows.single.sessionLabel, 'Pipeline');
      expect(rows.single.displayName, 'flutter build');
      expect(rows.single.pid, 200);
      expect(rows.single.depth, 1);
    });

    test(
      'marks project-linked build process without tracked parent as orphan',
      () {
        final rows = classifier.classify(
          trackedShellPids: const {},
          showAllChildren: false,
          projectRoot: project,
          selfPid: 1,
          rows: const [
            RawProcessRow(
              command: 'java -gradle-daemon $project',
              ppid: 50,
              pid: 300,
            ),
          ],
        );

        expect(rows, hasLength(1));
        expect(rows.single.kind, ProcessKind.orphan);
      },
    );

    test('ignores unrelated build processes', () {
      final rows = classifier.classify(
        trackedShellPids: const {},
        showAllChildren: false,
        projectRoot: project,
        selfPid: 1,
        rows: const [
          RawProcessRow(command: 'flutter doctor', ppid: 50, pid: 400),
        ],
      );

      expect(rows, isEmpty);
    });

    test('includes non-build shell children when showAllChildren is true', () {
      final rows = classifier.classify(
        trackedShellPids: const {'session_a': 100},
        showAllChildren: true,
        projectRoot: project,
        selfPid: 1,
        rows: const [
          RawProcessRow(command: 'sh', ppid: 1, pid: 100),
          RawProcessRow(command: 'sleep 30', ppid: 100, pid: 201),
          RawProcessRow(command: 'flutter pub get', ppid: 100, pid: 202),
        ],
      );

      expect(rows.map((row) => row.pid), containsAll([201, 202]));
      expect(rows.firstWhere((row) => row.pid == 202).kind, ProcessKind.active);
      expect(rows.firstWhere((row) => row.pid == 201).kind, ProcessKind.active);
    });

    test('hides non-build shell children when showAllChildren is false', () {
      final rows = classifier.classify(
        trackedShellPids: const {'session_a': 100},
        showAllChildren: false,
        projectRoot: project,
        selfPid: 1,
        rows: const [
          RawProcessRow(command: 'sh', ppid: 1, pid: 100),
          RawProcessRow(command: 'sleep 30', ppid: 100, pid: 201),
          RawProcessRow(command: 'flutter pub get', ppid: 100, pid: 202),
        ],
      );

      expect(rows.map((row) => row.pid), [202]);
    });

    test('excludes self and tracked shell pids', () {
      final rows = classifier.classify(
        trackedShellPids: const {'session_a': 100},
        showAllChildren: true,
        projectRoot: project,
        selfPid: 1,
        rows: const [
          RawProcessRow(command: 'fluship', ppid: 0, pid: 1),
          RawProcessRow(command: 'sh', ppid: 1, pid: 100),
        ],
      );

      expect(rows, isEmpty);
    });
  });
}
