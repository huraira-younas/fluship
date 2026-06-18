import 'package:equatable/equatable.dart';

enum ConsoleStream { input, stdout, stderr, system }

class ConsoleLine extends Equatable {
  const ConsoleLine({required this.stream, required this.text});

  final ConsoleStream stream;
  final String text;

  ConsoleLine copyWith({ConsoleStream? stream, String? text}) => ConsoleLine(
    stream: stream ?? this.stream,
    text: text ?? this.text,
  );

  @override
  List<Object?> get props => [stream, text];
}
