import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

class Skip extends Processor<String, String> {
  Skip(this.linesToSkip);
  int linesToSkip;
  @override
  Future<CompleterEx<void>> start(
    Stream<String> srcIn,
    Stream<String> srcErr,
  ) async {
    var count = linesToSkip;

    final done = CompleterEx<void>(debugName: 'SkipSection');
    // do not pass the first [lineToSkip]
    srcIn.listen((line) {
      if (count > 0) {
        count--;
      } else {
        outController.sink.add(line);
      }
    })
      ..onDone(done.complete)
      ..onError(done.completeError);

    // write [srcErr] directly to [sinkErr]
    await errController.sink.addStream(srcErr);

    return done;
  }

  @override
  StreamController<String> get errController => StreamController<String>();

  @override
  StreamController<String> get outController => StreamController<String>();
}
