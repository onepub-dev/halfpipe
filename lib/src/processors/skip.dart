import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class Skip extends Processor<String, String> {
  Skip(this.linesToSkip);
  int linesToSkip;
  final _done = CompleterEx<void>(debugName: 'SkipSection');

  late final StreamControllerEx<String> srcIn;
  late final StreamControllerEx<String> srcErr;

  @override
  Future<void> get waitUntilOutputDone => _done.future;

  @override
  Future<void> wire(StreamControllerEx<String> srcIn,
      StreamControllerEx<String> srcErr) async {
    this.srcIn = srcIn;
    this.srcErr = srcErr;

    var count = linesToSkip;

    // do not pass the first [lineToSkip]
    srcIn.stream.listen((line) {
      if (count > 0) {
        count--;
      } else {
        outController.sink.add(line);
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
    await errController.sink.addStream(srcErr.stream);
  }

  @override
  Future<void> start() async {}

  @override
  String get debugName => 'skip';
}
