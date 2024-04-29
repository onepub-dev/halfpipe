import 'dart:async';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class Skip extends Processor<String, String> {
  Skip(this.linesToSkip);
  int linesToSkip;
  @override
  Future<void> start(
    Stream<String> srcIn,
    Stream<String> srcErr,
  ) async {
    var count = linesToSkip;

    // do not pass the first [lineToSkip]
    srcIn.listen((line) {
      if (count > 0) {
        count--;
      } else {
        outController.sink.add(line);
      }
    });

    // write [srcErr] directly to [sinkErr]
    await errController.sink.addStream(srcErr);
  }

  @override
  StreamControllerEx<String> get errController =>
      StreamControllerEx<String>(debugName: 'skip: err');

  @override
  StreamControllerEx<String> get outController =>
      StreamControllerEx<String>(debugName: 'skip: out');
}
