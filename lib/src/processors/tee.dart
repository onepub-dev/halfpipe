import 'dart:async';
import 'dart:io';

import '../pipeline/pipe_phase.dart';
import 'pass_through.dart';
import 'processor.dart';

class Tee<T> extends Processor<T, T> {
  Tee(this.other) {
    /// Add an injector to the start of the pipeline so we can become
    /// the source.
    other.sections.insert(0, injector);
  }

  PassThrough<T, T> injector = PassThrough();
  PipePhase<T> other;
  @override
  Future<void> start(Stream<T> srcIn, Stream<T> srcErr) async {
    srcIn.listen((line) {
      stdout.writeln(line);
    });
    await injector.outController.sink.addStream(srcIn);

    srcErr.listen((line) {
      stderr.writeln(line);
      injector.errController.sink.add(line);
    });
  }

  @override
  StreamController<T> get errController => StreamController<T>();

  @override
  StreamController<T> get outController => StreamController<T>();
}
