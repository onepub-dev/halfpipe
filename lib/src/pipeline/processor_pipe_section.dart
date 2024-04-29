// ignore_for_file: avoid_returning_this

import 'dart:async';

import '../processors/processor.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class ProcessorPipeSection<I, O> extends PipeSection<I, O> {
  ProcessorPipeSection(this.transformer);

  Processor<I, O> transformer;

  @override
  Future<void> start(Stream<I> srcIn, Stream<I> srcErr) async {
    await transformer.start(srcIn, srcErr);
  }

  @override
  StreamControllerEx<O> get errController =>
      StreamControllerEx<O>(debugName: 'Processor: err');

  @override
  StreamControllerEx<O> get outController =>
      StreamControllerEx<O>(debugName: 'Processor: out');
}
