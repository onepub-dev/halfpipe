import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class PassThrough<I> extends Processor<I, I> {
  final _done = CompleterEx<void>(debugName: 'PassThrough: done');

  @override
  Future<void> get waitUntilOutputDone => _done.future;

  late final StreamControllerEx<I> srcIn;
  late final StreamControllerEx<I> srcErr;

  final inCompleter = CompleterEx<void>(debugName: 'PassThrough: In');
  final errCompleter = CompleterEx<void>(debugName: 'PassThrough: Err');

  @override
  Future<void> wire(
      StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async {
    this.srcIn = srcIn;
    this.srcErr = srcErr;

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
  }

  @override
  Future<void> start() async {
    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => _done.complete));
  }

  @override
  String get debugName => 'pass through';
}
