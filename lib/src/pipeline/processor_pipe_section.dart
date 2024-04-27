// ignore_for_file: avoid_returning_this

import 'dart:async';

import '../processors/processor.dart';
import 'pipe_section.dart';

class ProcessorPipeSection<I, O> extends PipeSection<I, O> {
  ProcessorPipeSection(this.transformer);

  Processor<I, O> transformer;

  @override
  Future<void> start(Stream<I> srcIn, Stream<I> srcErr) async {
    await transformer.start(srcIn, srcErr);
  }

  @override
  StreamController<O> get errController => StreamController<O>();

  @override
  StreamController<O> get outController => StreamController<O>();
}
