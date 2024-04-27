import 'dart:async';
import 'dart:convert';

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
  StreamController<O> get errController => StreamController<O>();

  @override
  StreamController<O> get outController => StreamController<O>();

  static Utf8LineSplitter get line => Utf8LineSplitter();
}
