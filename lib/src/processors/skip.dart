import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class Skip extends Processor<String, String> {
  Skip(this.linesToSkip);
  int linesToSkip;
  @override
  final done = CompleterEx<void>(debugName: 'SkipSection');
  @override
  Future<void> start(
    StreamControllerEx<String> srcIn,
    StreamControllerEx<String> srcErr,
  ) async {
    var count = linesToSkip;

    // do not pass the first [lineToSkip]
    srcIn.stream.listen((line) {
      if (count > 0) {
        count--;
      } else {
        outController.sink.add(line);
      }
    })
      ..onDone(done.complete)
      ..onError(done.completeError);

    // write [srcErr] directly to [sinkErr]
    await errController.sink.addStream(srcErr.stream);
  }

  @override
  String get debugName => 'skip';
}
