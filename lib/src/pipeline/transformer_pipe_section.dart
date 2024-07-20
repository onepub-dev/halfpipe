// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  TransformerPipeSection(this.transformer);

  final _log = Logger((TransformerPipeSection).toString());

  final Converter<I, O> transformer;

  late final Sink<I>? inputConversionSinkForOut;
  late final Sink<I>? inputConversionSinkForErr;

  final outCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: out');
  final errCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: err');

  @override
  Future<void> addPlumbing() async {
    inputConversionSinkForOut =
        transformer.startChunkedConversion(sinkOutController.sink);
    inputConversionSinkForErr =
        transformer.startChunkedConversion(sinkErrController.sink);

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
  }

  @override
  Future<void> start() async =>
      Future.wait([outCompleter.future, errCompleter.future]) as Future<void>;

  @override
  Future<void> close() async {
    inputConversionSinkForOut?.close();
    inputConversionSinkForErr?.close();
    await super.close();
  }

  @override
  String get debugName => 'transformer';
}
