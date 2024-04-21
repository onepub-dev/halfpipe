import 'dart:async';
import 'dart:io';

import 'processor.dart';

class PassThrough<T> extends Processor<T> {

  
  final srcOutController = StreamController<List<T>> ();
  final srcErrController = StreamController<List<T>> ();

  @override
  Future<void> start(Stream<List<T>> srcIn, Stream<List<T>> srcErr,
      StreamSink<List<T>> sinkOut, StreamSink<List<T>> sinkErr) async {
    srcIn.listen((line) {
      stdout.writeln(line);
    });

    srcErr.listen((line) {
      stderr.writeln(line);
    });
  }
}
