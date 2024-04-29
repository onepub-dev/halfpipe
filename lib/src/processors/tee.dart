import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import '../pipeline/pipe_phase.dart';
import '../util/stream_controller_ex.dart';
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
  Future<CompleterEx<void>> start(
      StreamControllerEx<T> srcIn, StreamControllerEx<T> srcErr) async {
    final inCompleter = CompleterEx<void>(debugName: 'Tee:Stdout');
    srcIn.stream.listen((line) {
      stdout.writeln(line);
    })
      ..onDone(inCompleter.complete)
      ..onError(inCompleter.completeError);

    await injector.outController.addStream(srcIn.stream);

    final errCompleter = CompleterEx<void>(debugName: 'Tee:Stdout');
    srcErr.stream.listen((line) {
      stderr.writeln(line);
      injector.errController.add(line);
    })
      ..onDone(errCompleter.complete)
      ..onError(errCompleter.completeError);

    final done = CompleterEx<void>(debugName: 'Tee');

    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => done.complete()));

    return done;
  }

  @override
  String get debugName => 'tee';
}
