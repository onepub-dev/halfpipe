// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  TransformerPipeSection(this.transformer);

  Converter<List<I>, List<O>> transformer;

  @override
  Future<void> start(
      Stream<List<dynamic>> srcIn,
      Stream<List<dynamic>> srcErr,
      StreamSink<List<dynamic>> sinkOut,
      StreamSink<List<dynamic>> sinkErr) async {
    srcIn.listen((data) {
      sinkOut.add(transformer.convert(data as List<I>));
    });
    srcErr.listen((data) {
      sinkErr.add(transformer.convert(data as List<I>));
    });
  }
}
