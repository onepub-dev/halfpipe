import 'dart:async';
import 'dart:convert';

import '../util/stream_controller_ex.dart';
import 'transformer.dart';
import 'utf8_line_splitter.dart';

class Transform<I, O> extends Transformer<I, O> {
  Transform(this.converter);
  Converter<I, O> converter;

  @override
  Future<void> start(Stream<I> srcIn, Stream<I> srcErr) async {
    srcIn.transform(converter).listen((event) {
      outController.sink.add(event);
    }, onDone: () async {
      await outController.sink.close();
      await errController.sink.close();
    });
  }

  @override
  StreamControllerEx<O> get errController =>
      StreamControllerEx<O>(debugName: 'tranform: err');

  @override
  StreamControllerEx<O> get outController =>
      StreamControllerEx<O>(debugName: 'transform: out');

  static Utf8LineSplitter get line => Utf8LineSplitter();
}
