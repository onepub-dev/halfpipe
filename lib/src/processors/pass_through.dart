import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class PassThrough<I, O> extends Processor<I, O> {
  @override
  final done = CompleterEx<void>(debugName: 'PassThrough: done');
  @override
  Future<void> start(
      StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async {
    final inCompleter = CompleterEx<void>(debugName: 'PassThrough: In');
    srcIn.stream.listen((line) {
      stdout.writeln(line);
    })
      ..onDone(inCompleter.complete)
      ..onError(inCompleter.completeError);

    final errCompleter = CompleterEx<void>(debugName: 'PassThrough: Err');
    srcErr.stream.listen((line) {
      stderr.writeln(line);
    })
      ..onDone(errCompleter.complete)
      ..onError(errCompleter.completeError);

    unawaited(Future.wait([inCompleter.future, errCompleter.future])
        .then((_) => done.complete));
  }

  @override
  String get debugName => 'pass through';
}
