import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'transformer.dart';
import 'utf8_line_splitter.dart';

class Transform<I, O> extends Transformer<I, O> {
  Transform(this.converter);
  Converter<I, O> converter;

  @override
  Future<CompleterEx<void>> start(
      StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async {
    final done = CompleterEx<void>(debugName: 'Transform');
    srcIn.stream.transform(converter).listen((event) {
      outController.sink.add(event);
    }, onDone: () async {
      await outController.sink.close();
      await errController.sink.close();
      done.complete();
    }, onError: done.completeError);

    return done;
  }

  static Utf8LineSplitter get line => Utf8LineSplitter();

  @override
  String get debugName => 'transform';
}
