import 'dart:async';

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

  PassThrough<T> injector = PassThrough();
  PipePhase<T> other;

  final _done = CompleterEx<void>(debugName: 'Tee');

  final inCompleter = CompleterEx<void>(debugName: 'Tee:in');
  final errCompleter = CompleterEx<void>(debugName: 'Tee:err');

  @override
  Future<void> addPlumbing() async {
    srcIn.stream.listen((data) {
      sinkOutController.sink.add(data);
      injector.sinkOutController.add(data);
    })
      ..onDone(() {
        // onError may already have called completed
        if (!inCompleter.isCompleted) {
          inCompleter.complete();
        }
      })
      ..onError(inCompleter.completeError);

    srcErr.stream.listen((line) {
      sinkErrController.sink.add(line);
      injector.sinkErrController.add(line);
    })
      ..onDone(() {
        // onError may already have called completed
        if (!errCompleter.isCompleted) {
          errCompleter.complete();
        }
      })
      ..onError(errCompleter.completeError);
  }

  @override
  Future<void> start() async {
    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => _done.complete()));

    return _done.future;
  }

  @override
  String get debugName => 'tee';
}
