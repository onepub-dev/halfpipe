import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';

import 'transformer.dart';
import 'utf8_line_splitter.dart';

class Transform<I, O> extends Transformer<I, O> {
  Transform(this.converter);
  Converter<I, O> converter;

  final _done = CompleterEx<void>(debugName: 'Transform');

  @override
  Future<void> addPlumbing() async {
    src.stream.transform(converter).listen((event) {
      sinkController.sink.add(event);
    }, onDone: () async {
      // onError may already have called completed
      if (!_done.isCompleted) {
        _done.complete();
      }
    }, onError: _done.completeError);
  }

  @override
  Future<void> start() async => _done.future;

  static Utf8LineSplitter get line => Utf8LineSplitter();

  @override
  String get debugName => 'transform';
}
