// ignore_for_file: avoid_returning_this

import 'dart:async';

abstract class PipeSection<I, O> {
  PipeSection() {
    // sinkOut = sinkOutController.sink;
    // sinkErr = sinkErrController.sink;
  }

  /// Runs the defined action passing in data from the previous [PipeSection]
  /// and passing data out to the next [PipeSection].
  /// [srcIn] is a stream from the prior [PipeSection] equivalent stdout.
  /// [srcErr] is a stream from the prior [PipeSection] equivalent to stderr.
  /// [sinkOut] is where this [PipeSection] writes it's 'good' data.
  /// [sinkErr] is where this [PipeSection] writes its 'bad'data.
  /// A Future is returned that completes when this [PipeSection] has completed
  /// generating/processing the [srcIn] and [srcErr] streams.
  Future<void> start(Stream<List<I>> srcIn, Stream<List<I>> srcErr,
      StreamSink<List<O>> sinkOut, StreamSink<List<O>> sinkErr);

  /// Each PipeSection is wired to the next and previous [PipeSection]
  /// via streams.

  // /// input from the prior pipe-section
  // late final srcInController = StreamController<List<I>>();
  // late final StreamSubscription<List<I>> srcIn;

  // late final srcErrController = StreamController<List<I>>();
  // late final StreamSubscription<List<I>> srcErr;

  // /// send data to stdout
  // late final sinkOutController = StreamController<List<O>>();
  // late final StreamSink<List<O>> sinkOut;

  // /// send data to stderr
  // late final sinkErrController = StreamController<List<O>>();
  // late final StreamSink<List<O>> sinkErr;

  // Future<void> close() async {
  //   await srcInController.close();
  //   await srcErrController.close();

  //   await sinkOutController.close();
  //   await sinkErrController.close();

  //   await srcIn.cancel();
  //   await sinkOut.close();
  //   await sinkErr.close();
  // }
}
