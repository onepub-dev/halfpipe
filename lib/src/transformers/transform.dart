import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';

import 'transformer.dart';
import 'utf8_line_splitter.dart';

class Transform<I, O> extends Transformer<I, O> {
  Transform(this.converter);
  Converter<I, O> converter;

  @override
  Future<CompleterEx<void>> start(Stream<I> srcIn, Stream<I> srcErr) async {
    final done = CompleterEx<void>(debugName: 'Transform');
    srcIn.transform(converter).listen((event) {
      outController.sink.add(event);
    }, onDone: () async {
      await outController.sink.close();
      await errController.sink.close();
      done.complete();
    }, onError: done.completeError);

    return done;
  }

  @override
  StreamController<O> get errController => StreamController<O>();

  @override
  StreamController<O> get outController => StreamController<O>();

  static Utf8LineSplitter get line => Utf8LineSplitter();
}
