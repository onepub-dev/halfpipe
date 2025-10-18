// processors/progress_bytes.dart
import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import '../processors/processor.dart';

/// Pass-through byte progress meter.
/// - Forwards src -> sink without buffering
/// - Calls [onTick] every [interval] with (seenBytes, elapsed)
/// - Also provides a convenience .printer() that writes a single \r line
class ProgressBytes extends Processor<List<int>, List<int>> {
  final void Function(int seenBytes, Duration elapsed) onTick;

  final Duration interval;

  final log = Logger((ProgressBytes).toString());

  late final _done = CompleterEx<void>(debugName: 'ProgressBytes');

  Timer? _timer;

  late DateTime _start;

  var _seen = 0;

  StreamSubscription<List<int>>? _inSub;

  StreamSubscription<List<int>>? _errSub;

  ProgressBytes(
    this.onTick, {
    this.interval = const Duration(seconds: 1),
  });

  /// Convenience constructor that prints human-friendly progress to stderr.
  /// If [totalBytes] is provided, prints a percentage as well.
  ProgressBytes.printer({
    this.interval = const Duration(seconds: 1),
    int? totalBytes,
    String label = 'Restoring',
  }) : onTick = ((seen, elapsed) {
          final secs = elapsed.inMilliseconds / 1000.0;
          final mb = seen / (1024 * 1024);
          final rate = secs > 0 ? mb / secs : 0.0;
          final pct = totalBytes != null && totalBytes > 0
              ? (seen / totalBytes * 100).clamp(0, 100)
              : null;

          final pctStr = pct != null ? ' (${pct.toStringAsFixed(1)}%)' : '';
          stderr.write(
            '\r$label: ${mb.toStringAsFixed(1)} MiB$pctStr '
            '@ ${rate.toStringAsFixed(1)} MiB/s   ',
          );
        });

  @override
  Future<void> addPlumbing() async {
    // Forward upstream stderr unmodified
    _errSub = srcErr.stream.listen(sinkErrController.sink.add);

    // Count bytes and pass through to next stage
    _inSub = src.stream.listen(
      (chunk) {
        _seen += chunk.length;
        sinkController.sink.add(chunk);
      },
      onError: (Object e, StackTrace st) {
        if (!_done.isCompleted) {
          _done.completeError(e, st);
        }
      },
      onDone: () {
        if (!_done.isCompleted) {
          _done.complete();
        }
      },
    );
  }

  @override
  Future<void> start() {
    _start = DateTime.now();
    _timer = Timer.periodic(interval, (_) {
      onTick(_seen, DateTime.now().difference(_start));
    });
    return _done.future;
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _inSub?.cancel();
    await _errSub?.cancel();
  }

  @override
  String get debugName => 'progress-bytes';
}
