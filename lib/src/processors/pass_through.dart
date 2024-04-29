import 'dart:async';
import 'dart:io';

import '../util/stream_controller_ex.dart';
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
  StreamControllerEx<O> get errController =>
      StreamControllerEx<O>(debugName: 'pass through: err');

  @override
  StreamControllerEx<O> get outController =>
      StreamControllerEx<O>(debugName: 'pass through: out');
}
