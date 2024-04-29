import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

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
  Future<CompleterEx<void>> start(Stream<T> srcIn, Stream<T> srcErr) async {
    final inCompleter = CompleterEx<void>(debugName: 'Tee:Stdout');
    srcIn.listen((line) {
      stdout.writeln(line);
    })
      ..onDone(inCompleter.complete)
      ..onError(inCompleter.completeError);

    await injector.outController.sink.addStream(srcIn);

    final errCompleter = CompleterEx<void>(debugName: 'Tee:Stdout');
    srcErr.listen((line) {
      stderr.writeln(line);
      injector.errController.sink.add(line);
    })
      ..onDone(errCompleter.complete)
      ..onError(errCompleter.completeError);

    final done = CompleterEx<void>(debugName: 'Tee');

    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => done.complete()));

    return done;
  }

  @override
  StreamController<T> get errController => StreamController<T>();

  @override
  StreamController<T> get outController => StreamController<T>();
}
