// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  TransformerPipeSection(this.transformer);

  Converter<I, O> transformer;

  @override
  Future<void> start(Stream<dynamic> srcIn, Stream<dynamic> srcErr,
      ) async {
    final inputConversionSinkForOut =
        transformer.startChunkedConversion(outController.sink as Sink<O>);
    final inputConversionSinkForErr =
        transformer.startChunkedConversion(errController.sink as Sink<O>);
    srcIn.listen((data) {
      inputConversionSinkForOut.add(data as I);
    }, onDone: () {
      inputConversionSinkForOut.close();
      outController.sink.close();
    });
    srcErr.listen((data) {
      inputConversionSinkForErr.add(data as I);
    }, onDone: () {
      inputConversionSinkForErr.close();
      errController.sink.close();
    });
  }

  @override
  StreamController<O> get errController => StreamController<O>();

  @override
  StreamController<O> get outController => StreamController<O>();
}
