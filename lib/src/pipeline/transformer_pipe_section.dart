// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  TransformerPipeSection(this.transformer);

  final _log = Logger((TransformerPipeSection).toString());

  Converter<I, O> transformer;

  Sink<I>? inputConversionSinkForOut;
  Sink<I>? inputConversionSinkForErr;
  // If we wait now then we stop the next stage in the pipeline
  // from running.
  // exitCode = await runProcess.exitCode;
  final _done = CompleterEx<void>(debugName: 'TransformerSection: done');

  @override
  Future<void> get waitUntilComplete => _done.future;

  @override
  Future<void> start(
    StreamControllerEx<I> srcIn,
    StreamControllerEx<I> srcErr,
  ) async {
    final outCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: out');
    final errCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: err');

    inputConversionSinkForOut =
        transformer.startChunkedConversion(outController.sink);
    inputConversionSinkForErr =
        transformer.startChunkedConversion(errController.sink);

    /// wire source
    srcIn.stream.listen((data) {
      _log.fine(() => 'Transformer: got data $data');
      inputConversionSinkForOut!.add(data);
    }, onDone: () {
      _log.fine(() => 'Transfomer: done - out');
      // onError may already have called completed
      if (!outCompleter.isCompleted) {
        outCompleter.complete(true);
      }
    }, onError: outCompleter.completeError);

    /// wire error
    srcErr.stream.listen((data) {
      _log.fine(() => 'Transformer: addErr');
      inputConversionSinkForErr!.add(data);
    }, onDone: () {
      _log.fine(() => 'Transfomer: done - err');

      // onError may already have called completed
      if (!errCompleter.isCompleted) {
        errCompleter.complete(true);
      }
    }, onError: errCompleter.completeError);

    unawaited(Future.wait<bool>([outCompleter.future, errCompleter.future])
        // ignore: prefer_expression_function_bodies
        .then((_) {
      _done.complete();
    }));
  }

  @override
  Future<void> close() async {
    inputConversionSinkForOut?.close();
    inputConversionSinkForErr?.close();
    await super.close();
  }

  @override
  String get debugName => 'transformer';
}
