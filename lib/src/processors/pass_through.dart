import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class PassThrough<I, O> extends Processor<I, O> {
  @override
  Future<CompleterEx<void>> start(Stream<I> srcIn, Stream<I> srcErr) async {
    final inCompleter = CompleterEx<void>(debugName: 'PassThrough: In');
    srcIn.listen((line) {
      stdout.writeln(line);
    })
      ..onDone(inCompleter.complete)
      ..onError(inCompleter.completeError);

    final errCompleter = CompleterEx<void>(debugName: 'PassThrough: Err');
    srcErr.listen((line) {
      stderr.writeln(line);
    })
      ..onDone(errCompleter.complete)
      ..onError(errCompleter.completeError);

    final done = CompleterEx<void>(debugName: 'PassThrough: done');

    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => done.complete));
    return done;
  }

  @override
  StreamControllerEx<O> get errController =>
      StreamControllerEx<O>(debugName: 'pass through: err');

  @override
  StreamControllerEx<O> get outController =>
      StreamControllerEx<O>(debugName: 'pass through: out');
}
