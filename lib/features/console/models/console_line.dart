import 'package:equatable/equatable.dart';

enum ConsoleStream { input, stdout, stderr, system }

enum ConsoleLineKind { info, progress, success, warn, error }

class ConsoleLine extends Equatable {
  const ConsoleLine({
    this.complete = false,
    required this.stream,
    required this.text,
    this.kind,
  });

  final ConsoleLineKind? kind;
  final ConsoleStream stream;
  final String text;

  /// Finished log lines do not merge with later process chunks.
  final bool complete;

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
