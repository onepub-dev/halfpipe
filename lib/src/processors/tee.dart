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

  final _done = CompleterEx<void>(debugName: 'Tee');

  @override
  Future<void> get waitUntilComplete => _done.future;

  @override
  Future<void> start(
      StreamControllerEx<T> srcIn, StreamControllerEx<T> srcErr) async {
    final inCompleter = CompleterEx<void>(debugName: 'Tee:Stdout');
    srcIn.stream.listen((data) {
      stdout.write(data);
      injector.outController.add(data);
    })
      ..onDone(() {
        // onError may already have called completed
        if (!inCompleter.isCompleted) {
          inCompleter.complete();
        }
      })
      ..onError(inCompleter.completeError);

    final errCompleter = CompleterEx<void>(debugName: 'Tee:Stdout');
    srcErr.stream.listen((line) {
      stderr.writeln(line);
      injector.errController.add(line);
    })
      ..onDone(() {
        // onError may already have called completed
        if (!errCompleter.isCompleted) {
          errCompleter.complete(true);
        }
      })
      ..onError(errCompleter.completeError);

    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => _done.complete()));
  }

  @override
  String get debugName => 'tee';
}
