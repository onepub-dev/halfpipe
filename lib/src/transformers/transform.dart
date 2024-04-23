import 'dart:async';
import 'dart:convert';

import 'transformer.dart';
import 'utf8_line_splitter.dart';

class Transform<I, O> extends Transformer<I, O> {
  Transform(this.converter);
  Converter<List<I>, List<O>> converter;

  @override
  Future<void> start(Stream<List<I>> srcIn, Stream<List<I>> srcErr,
      StreamSink<List<O>> sinkOut, StreamSink<List<O>> sinkErr) async {
    srcIn.transform(converter).listen((event) => sinkOut.add(event),
        onDone: () async {
      await sinkOut.close();
      await sinkErr.close();
    });
  }

  static Utf8LineSplitter get line => Utf8LineSplitter();
}
