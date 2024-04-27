import 'dart:async';
import 'dart:io';

import 'processor.dart';

class PassThrough<I, O> extends Processor<I, O> {
  @override
  Future<void> start(Stream<I> srcIn, Stream<I> srcErr) async {
    srcIn.listen((line) {
      stdout.writeln(line);
    });

    srcErr.listen((line) {
      stderr.writeln(line);
    });
  }

  @override
  StreamController<O> get errController => StreamController<O>();

  @override
  StreamController<O> get outController => StreamController<O>();
}
