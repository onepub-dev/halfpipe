import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

typedef ProgressCallback = void Function(int count, int total);

/// A [Processor] that reports progress.
/// The [callback] will be called for each 1% of data
/// processed.
class Progress<I> extends Processor<I, I> {
  Progress(this.size, this.callback) : increment = size ~/ 100;
  final int size;
  final int increment;
  final ProgressCallback callback;
  final _done = CompleterEx<void>(debugName: 'ProgressSection');

  int written = 0;
  int last = 0;

  @override
  Future<void> addPlumbing() async {
    src.stream.listen((data) {
      written += (data is List<int>) ? data.length : 1;
      if (written > last + increment) {
        var reported = false;
        if (written ~/ increment > last) {
          last = written ~/ increment;
          callback(written, size);
          reported = true;
        }
        if (written == size && !reported) {
          callback(written, size);
        }

        sinkController.sink.add(data);
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
  String get debugName => 'progress';
}
