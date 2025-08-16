import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

/// A process designed to skil a number of lines
/// in the input.
///
/// ```dart
///   (await HalfPipe()
///      .processor(ReadFile(pathToLineFile))
///      .transform(Transform.line)
///       // skip the first 5 lines that pass through the processor
///      .processor<String>(Skip(5))
///      .captureOut())
///  .toParagraph();
///```
class Skip extends Processor<String, String> {
  int linesToSkip;

  final _done = CompleterEx<void>(debugName: 'SkipSection');

  Skip(this.linesToSkip);

  @override
  Future<void> addPlumbing() async {
    var count = linesToSkip;

    // do not pass the first 'n' [linesToSkip]
    src.stream.listen((line) {
      if (count > 0) {
        count--;
      } else {
        sinkController.sink.add(line);
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
  Future<void> start()  => _done.future;

  @override
  String get debugName => 'skip';
}
