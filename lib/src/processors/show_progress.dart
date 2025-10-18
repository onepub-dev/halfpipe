import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

typedef ProgressCallback = void Function(int count, int total);

/// A [Processor] that reports progress.
/// The [callback] will be called for each 1% of data
/// processed.
/// The src and srcErr streams are automatially plumbed through to the next
/// section.
class ShowProgress<I> extends Processor<I, I> {
  final int size;

  final int increment;

  final ProgressCallback callback;

  final _done = CompleterEx<void>(debugName: 'ProgressSection');

  // part of the public api
  // ignore: omit_obvious_property_types
  int written = 0;

  // part of the public api
  // ignore: omit_obvious_property_types
  int last = 0;

  ShowProgress(this.size, this.callback) : increment = size ~/ 100;

  @override
  Future<void> addPlumbing() async {
    src.stream.listen((data) {
      // Always forward the chunk first
      sinkController.sink.add(data);

      final inc = increment == 0 ? size : increment;
      final delta = (data is List<int>) ? data.length : 1;
      written += delta;

      // Report when we cross the next increment boundary
      if (written >= last + inc) {
        last = (written ~/ inc) * inc;
        callback(written, size);
      } else if (written == size) {
        callback(written, size);
      }
    }, onDone: () {
      if (!_done.isCompleted) {
        _done.complete();
      }
    }, onError: (Object e, StackTrace st) {
      if (!_done.isCompleted) {
        _done.completeError(e, st);
      }
    });

    // pass-through stderr
    srcErr.stream.listen(
      sinkErrController.sink.add,
      onError: (Object e, StackTrace st) =>
          sinkErrController.sink.addError(e, st),
    );
  }

  @override
  Future<void> start() => _done.future;

  @override
  String get debugName => 'progress';
}
