import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'transformer.dart';
import 'utf8_line_splitter.dart';

class Transform<I, O> extends Transformer<I, O> {
  Transform(this.converter);
  Converter<I, O> converter;

  final _done = CompleterEx<void>(debugName: 'Transform');
  late final StreamControllerEx<I> srcIn;
  late final StreamControllerEx<I> srcErr;

  @override
  Future<void> get waitUntilOutputDone => _done.future;

  @override
  Future<void> wire(
      StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async {
    this.srcIn = srcIn;
    this.srcErr = srcErr;
    srcIn.stream.transform(converter).listen((event) {
      outController.sink.add(event);
    }, onDone: () async {
      // onError may already have called completed
      if (!_done.isCompleted) {
        _done.complete();
      }
    }, onError: _done.completeError);
  }

  @override
  Future<void> start() async {}

  static Utf8LineSplitter get line => Utf8LineSplitter();

  @override
  String get debugName => 'transform';
}
