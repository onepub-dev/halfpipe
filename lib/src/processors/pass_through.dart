import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

class PassThrough<I> extends Processor<I, I> {
  final _done = CompleterEx<void>(debugName: 'PassThrough: done');

  final inCompleter = CompleterEx<void>(debugName: 'PassThrough: In');
  final errCompleter = CompleterEx<void>(debugName: 'PassThrough: Err');

  @override
  Future<void> addPlumbing() async {
    src.stream.listen((line) {
      sinkController.sink.add(line);
    })
      ..onDone(() {
        // onError may already have called completed
        if (!inCompleter.isCompleted) {
          inCompleter.complete();
        }
      })
      ..onError(inCompleter.completeError);

    srcErr.stream.listen((data) {
      sinkErrController.sink.add(data);
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
        .then((_) => _done.complete));

    return _done.future;
  }

  @override
  String get debugName => 'pass through';
}
