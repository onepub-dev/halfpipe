// ignore_for_file: avoid_returning_this

import 'dart:async';

import '../processors/processor.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class ProcessorPipeSection<I, O> extends PipeSection<I, O> {
  ProcessorPipeSection(this.processor);

  Processor<I, O> processor;

  @override
  Future<void> get waitUntilComplete => processor.waitUntilComplete;

  @override
  Future<void> start(
          StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async =>
      processor.start(srcIn, srcErr);

  @override
  String get debugName => 'processor';
}
