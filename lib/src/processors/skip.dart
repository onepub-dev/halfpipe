import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

class Skip extends Processor<String, String> {
  Skip(this.linesToSkip);
  int linesToSkip;
  final _done = CompleterEx<void>(debugName: 'SkipSection');

  @override
  Future<void> addPlumbing() async {
    var count = linesToSkip;

    // do not pass the first [lineToSkip]
    srcIn.stream.listen((line) {
      if (count > 0) {
        count--;
      } else {
        sinkOutController.sink.add(line);
      }
    })
      ..onDone(() {
        // onError may already have called completed
        if (!_done.isCompleted) {
          _done.complete();
        }
      })
      ..onError(_done.completeError);

    // write [srcErr] directly to [sinkErr]
    srcErr.stream.listen((line) => sinkErrController.sink.add(line));
  }

  @override
  Future<void> start() async => _done.future;

  @override
  String get debugName => 'skip';
}
