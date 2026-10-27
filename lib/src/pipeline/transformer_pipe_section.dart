// builder.
// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import 'pipe_section.dart';

class TransformerPipeSection<I, O> extends PipeSection<I, O> {
  final _log = Logger((TransformerPipeSection).toString());

  final Converter<I, O> transformer;

  late final Sink<I>? inputConversionSinkForOut;

  late final Sink<I>? inputConversionSinkForErr;

  final outCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: out');

  final errCompleter = CompleterEx<bool>(debugName: 'TransformerPipe: err');

  TransformerPipeSection(this.transformer);

  @override
  Future<void> addPlumbing() async {
    inputConversionSinkForOut = transformer.startChunkedConversion(
      sinkController.sink,
    );
    inputConversionSinkForErr = transformer.startChunkedConversion(
      sinkErrController.sink,
    );

    /// wire source
    src.stream.listen(
      (data) {
        _log.fine(() => 'Transformer: got data $data');
        if (outCompleter.isCompleted) {
          return;
        }
        try {
          inputConversionSinkForOut!.add(data);
        } on Object catch (error, stackTrace) {
          outCompleter.completeError(error, stackTrace);
        }
      },
      onDone: () {
        _log.fine(() => 'Transfomer: done - out');
        // onError may already have called completed
        if (!outCompleter.isCompleted) {
          outCompleter.complete(true);
        }
      },
      onError: (Object error, [StackTrace? stackTrace]) {
        if (!outCompleter.isCompleted) {
          outCompleter.completeError(error, stackTrace);
        }
      },
    );

    /// wire error
    srcErr.stream.listen(
      (data) {
        _log.fine(() => 'Transformer: addErr');
        if (errCompleter.isCompleted) {
          return;
        }
        try {
          inputConversionSinkForErr!.add(data);
        } on Object catch (error, stackTrace) {
          errCompleter.completeError(error, stackTrace);
        }
      },
      onDone: () {
        _log.fine(() => 'Transfomer: done - err');

        // onError may already have called completed
        if (!errCompleter.isCompleted) {
          errCompleter.complete(true);
        }
      },
      onError: (Object error, [StackTrace? stackTrace]) {
        if (!errCompleter.isCompleted) {
          errCompleter.completeError(error, stackTrace);
        }
      },
    );
  }

  @override
  Future<void> start() async {
    await Future.wait([
      outCompleter.future,
      errCompleter.future,
    ], eagerError: true);
  }

  @override
  Future<void> close() async {
    Object? firstError;
    StackTrace? firstStackTrace;
    try {
      inputConversionSinkForOut?.close();
    } on Object catch (error, stackTrace) {
      firstError = error;
      firstStackTrace = stackTrace;
    }
    try {
      inputConversionSinkForErr?.close();
    } on Object catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
    try {
      await super.close();
    } on Object catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  @override
  String get debugName => 'transformer';
}
