// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  TransformerPipeSection(this.transformer);

  Converter<I, O> transformer;

  @override
  Future<void> start(
    Stream<dynamic> srcIn,
    Stream<dynamic> srcErr,
  ) async {
    final outCompleter = Completer<bool>();
    final errCompleter = Completer<bool>();

    final inputConversionSinkForOut =
        transformer.startChunkedConversion(outController.sink);
    final inputConversionSinkForErr =
        transformer.startChunkedConversion(errController.sink);
    srcIn.listen((data) {
      print('Transformer: addIn');
      inputConversionSinkForOut.add(data as I);
    }, onDone: () {
      inputConversionSinkForOut.close();
      outController.sink.close();
      outCompleter.complete(true);
    });
    srcErr.listen((data) {
      print('Transformer: addErr');
      inputConversionSinkForErr.add(data as I);
    }, onDone: () {
      inputConversionSinkForErr.close();
      errController.sink.close();
      errCompleter.complete(true);
    });

    // If we wait now then we stop the next stage in the pipeline
    // from running.
    // exitCode = await runProcess.exitCode;
    final done = Completer<void>();
    await Future.wait<bool>([outCompleter.future, errCompleter.future])
        // ignore: prefer_expression_function_bodies
        .then((_) {
      return done.complete;
    });
    return done.future;
  }

  @override
  StreamController<O> get errController => StreamController<O>();

  @override
  StreamController<O> get outController => StreamController<O>();
}
