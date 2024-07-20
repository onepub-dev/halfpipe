// ignore_for_file: avoid_returning_this

import 'dart:async';

import '../processors/processor.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class ProcessorPipeSection<I, O> extends PipeSection<I, O> {
  ProcessorPipeSection(this.processor);

  final Processor<I, O> processor;

  // final _log = Logger((ProcessorPipeSection).toString());

  @override
  Future<void> addPlumbing() async {
    await processor.initStreams(src, srcErr);
    await processor.addPlumbing();
  }

  @override
  Future<void> start() async {
    await processor.start();
  }

  @override
  Future<void> close() async {
    /// close will never complete if there are no listeners.
    if (processor.sinkController.hasListener) {
      await processor.sinkController.close();
    }

    /// close will never complete if there are no listeners.
    if (processor.sinkErrController.hasListener) {
      await processor.sinkErrController.close();
    }
  }

  // replace the controllers we inherit with the [processor]'s controllers as
  // there is no point in having an extra controller in the middle.
  @override
  StreamControllerEx<O> get sinkErrController => processor.sinkErrController;

  @override
  StreamControllerEx<O> get sinkController => processor.sinkController;

  @override
  String get debugName => 'processor:${processor.debugName}';
}
