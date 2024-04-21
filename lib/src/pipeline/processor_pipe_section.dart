// ignore_for_file: avoid_returning_this

import 'dart:async';

import '../processors/processor.dart';
import 'pipe_section.dart';

class ProcessorPipeSection<T> extends PipeSection<T, T> {
  ProcessorPipeSection(this.transformer);

  Processor<T> transformer;

  @override
  Future<void> start(Stream<List<T>> srcIn, Stream<List<T>> srcErr,
      StreamSink<List<T>> sinkOut, StreamSink<List<T>> sinkErr) async {
    await transformer.start(srcIn, srcErr, sinkOut, sinkErr);
  }
}
