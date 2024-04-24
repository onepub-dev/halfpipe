import 'dart:async';

import 'processor.dart';

class Skip extends Processor<String, String> {
  Skip(this.linesToSkip);
  int linesToSkip;
  @override
  Future<void> start(
      Stream<String> srcIn,
      Stream<String> srcErr,
      StreamSink<String> sinkOut,
      StreamSink<String> sinkErr) async {
    var count = linesToSkip;

    // do not pass the first [lineToSkip]
    srcIn.listen((line) {
      if (count > 0) {
        count--;
      } else {
        sinkOut.add(line);
      }
    });

    // write [srcErr] directly to [sinkErr]
    await sinkErr.addStream(srcErr);
  }

    @override
  StreamController<String> get errController => StreamController<String>();

  @override
  StreamController<String> get outController => StreamController<String>();

}
