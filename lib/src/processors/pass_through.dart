import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class PassThrough<I> extends Processor<I, I> {
  final _done = CompleterEx<void>(debugName: 'PassThrough: done');

  @override
  Future<void> get waitUntilOutputDone => _done.future;

  @override
  Future<void> start(
      StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async {
    final inCompleter = CompleterEx<void>(debugName: 'PassThrough: In');
    srcIn.stream.listen((line) {
      outController.sink.add(line);
    })
      ..onDone(() {
        // onError may already have called completed
        if (!inCompleter.isCompleted) {
          inCompleter.complete();
        }
      })
      ..onError(inCompleter.completeError);

    final errCompleter = CompleterEx<void>(debugName: 'PassThrough: Err');
    srcErr.stream.listen((data) {
      errController.sink.add(data);
    })
      ..onDone(() {
        // onError may already have called completed
        if (!errCompleter.isCompleted) {
          errCompleter.complete();
        }
      })
      ..onError(errCompleter.completeError);

    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => _done.complete));
  }

  @override
  String get debugName => 'pass through';
}
