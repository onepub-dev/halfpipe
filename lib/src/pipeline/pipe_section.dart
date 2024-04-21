// ignore_for_file: avoid_returning_this

import 'dart:async';

abstract class PipeSection<I, O> {
  PipeSection() {
    stdout = stdoutController.sink;
    stderr = stderrController.sink;
  }

  /// Runs the defined action passing in data from the previous [PipeSection]
  /// and passing data out to the next [PipeSection].
  /// [srcIn] is a stream from the prior [PipeSection] equivalent stdout.
  /// [srcErr] is a stream from the prior [PipeSection] equivalent to stderr.
  /// [sinkOut] is where this [PipeSection] writes it's 'good' data.
  /// [sinkErr] is where this [PipeSection] writes its 'bad'data.
  Future<void> start(Stream<List<I>> srcIn, Stream<List<I>> srcErr,
      StreamSink<List<O>> sinkOut, StreamSink<List<O>> sinkErr);

  /// Each PipeSection is wired to the next and previous [PipeSection]
  /// via streams.

  /// input from the prior pipe-section
  late final stdinController = StreamController<List<I>>();
  late final StreamSubscription<List<I>> stdin;

  /// send data to stdout
  late final stdoutController = StreamController<List<O>>();
  late final StreamSink<List<O>> stdout;

  /// send data to stderr
  late final stderrController = StreamController<List<O>>();
  late final StreamSink<List<O>> stderr;

  Future<void> close() async {
    await stdinController.close();
    await stdoutController.close();
    await stderrController.close();

    await stdin.cancel();
    await stdout.close();
    await stderr.close();
  }
}
