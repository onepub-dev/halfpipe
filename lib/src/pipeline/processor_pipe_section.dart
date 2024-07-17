// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:logging/logging.dart';

import '../processors/processor.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class ProcessorPipeSection<I, O> extends PipeSection<I, O> {
  ProcessorPipeSection(this.processor);

  final Processor<I, O> processor;
  late final StreamControllerEx<I> srcIn;
  late final StreamControllerEx<I> srcErr;

  final _log = Logger((ProcessorPipeSection).toString());

  @override
  Future<void> get waitUntilOutputDone => processor.waitUntilOutputDone;

  @override
  Future<void> wire(
      StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async {
    this.srcIn = srcIn;
    this.srcErr = srcErr;
    processor.wire(srcIn, srcErr);
  }

  @override
  Future<void> start() async {
    processor.start();
  }

  @override
  Future<void> close() async {
    _log.fine(() =>
        // ignore: lines_longer_than_80_chars
        'starting close of $debugName for ${processor.outController.debugName}');

    /// close will never complete if there are no listeners.
    if (processor.outController.hasListener) {
      await processor.outController.close();
    }
    _log
      ..fine(() => 'closed out of $debugName')
      ..fine(() => '''
starting close of $debugName for ${processor.errController.debugName}''');

    /// close will never complete if there are no listeners.
    if (processor.errController.hasListener) {
      await processor.errController.close();
    }
    _log.fine(() => 'closed err of $debugName');
  }

  // replace the controllers we inherit with the [processor]'s controllers as
  // there is no point in having an extra controller in the middle.
  @override
  StreamControllerEx<O> get errController => processor.errController;

  @override
  StreamControllerEx<O> get outController => processor.outController;

  @override
  String get debugName => 'processor:${processor.debugName}';
}
