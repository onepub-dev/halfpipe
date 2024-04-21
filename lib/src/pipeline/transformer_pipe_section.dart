// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  TransformerPipeSection(this.transformer);

  Converter<List<I>, List<O>> transformer;

  @override
  Future<void> start(Stream<List<I>> srcIn, Stream<List<I>> srcErr,
      StreamSink<List<O>> sinkOut, StreamSink<List<O>> sinkErr) async {
    srcIn.listen((data) {
      sinkOut.add(transformer.convert(data));
    });
    srcErr.listen((data) {
      sinkErr.add(transformer.convert(data));
    });
  }
}
