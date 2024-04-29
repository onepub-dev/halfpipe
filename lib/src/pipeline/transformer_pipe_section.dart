// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  TransformerPipeSection(this.transformer);

  Converter<I, O> transformer;

  @override
  Future<CompleterEx<void>> start(
    StreamControllerEx<dynamic> srcIn,
    StreamControllerEx<dynamic> srcErr,
  ) async {
    final outCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: out');
    final errCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: err');

    final inputConversionSinkForOut =
        transformer.startChunkedConversion(outController.sink);
    final inputConversionSinkForErr =
        transformer.startChunkedConversion(errController.sink);
    srcIn.stream.listen((data) {
      print('Transformer: addIn');
      inputConversionSinkForOut.add(data as I);
    }, onDone: () {
      inputConversionSinkForOut.close();
      // outController.sink.close();
      outCompleter.complete(true);
    }, onError: outCompleter.completeError);
    srcErr.stream.listen((data) {
      print('Transformer: addErr');
      inputConversionSinkForErr.add(data as I);
    }, onDone: () {
      inputConversionSinkForErr.close();
      errController.sink.close();
      errCompleter.complete(true);
    }, onError: errCompleter.completeError);

    // If we wait now then we stop the next stage in the pipeline
    // from running.
    // exitCode = await runProcess.exitCode;
    final done = CompleterEx<void>(debugName: 'TransformerSection: done');
    unawaited(Future.wait<bool>([outCompleter.future, errCompleter.future])
        // ignore: prefer_expression_function_bodies
        .then((_) {
      done.complete();
    }));
    return done;
  }

  @override
  String get debugName => 'transformer';
}
