import 'dart:async';

import 'processor.dart';

class Skip extends Processor<String> {
  Skip(this.linesToSkip);
  int linesToSkip;
  @override
  Future<void> start(
      Stream<List<String>> srcIn,
      Stream<List<String>> srcErr,
      StreamSink<List<String>> sinkOut,
      StreamSink<List<String>> sinkErr) async {
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
}
