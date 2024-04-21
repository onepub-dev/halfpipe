import 'dart:async';
import 'dart:io';

import '../pipeline/pipe_phase.dart';
import 'pass_through.dart';
import 'processor.dart';

class Tee<T> extends Processor<T> {
  Tee(this.other) {
    /// Add an injector to the start of the pipeline so we can become
    /// the source.
    other.sections.insert(0, injector);
  }

  PassThrough<T> injector = PassThrough();
  PipePhase<T> other;
  @override
  Future<void> start(Stream<List<T>> srcIn, Stream<List<T>> srcErr,
      StreamSink<List<T>> sinkOut, StreamSink<List<T>> sinkErr) async {
    srcIn.listen((line) {
      stdout.writeln(line);
      injector.srcInController.sink.add(line);
    });

    srcErr.listen((line) {
      stderr.writeln(line);
      injector.srcErrController.sink.add(line);
    });
  }
}
