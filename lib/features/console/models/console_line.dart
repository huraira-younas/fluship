import 'package:equatable/equatable.dart';

enum ConsoleStream { input, stdout, stderr, system }

enum ConsoleLineKind { info, progress, success, warn, error }

class const ConsoleLine({
  /// Finished log lines do not merge with later process chunks.
  final bool complete = false,
  required final ConsoleStream stream,
  required final String text,
  final ConsoleLineKind? kind,
}) extends Equatable {
  ConsoleLine copyWith({
    ConsoleStream? stream,
    ConsoleLineKind? kind,
    bool? complete,
    String? text,
  }) => ConsoleLine(
    complete: complete ?? this.complete,
    stream: stream ?? this.stream,
    kind: kind ?? this.kind,
    text: text ?? this.text,
  );

  @override
  List<Object?> get props => [stream, kind, text, complete];
}
