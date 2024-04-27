import 'dart:async';

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
  StreamController<String> get errController => StreamController<String>();

  @override
  StreamController<String> get outController => StreamController<String>();
}
