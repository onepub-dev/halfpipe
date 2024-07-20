// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import 'pipe_section.dart';

typedef BlockPlumber<I, O> = Future<void> Function(
    BlockPlumbing<I, O> plumbing);

class BlockPlumbing<I, O> {
  BlockPlumbing(this.src, this.srcErr, this.sink, this.sinkErr);

  Stream<I> src;
  Stream<I> srcErr;
  StreamSink<O> sink;
  StreamSink<O> sinkErr;

  /// Pipe [src] to [sink].
  void pipe(Stream<I> src, StreamSink<dynamic> sink) {
    src.listen((line) => sink.add(line));
  }
}

class BlockPipeSection<I, O> extends PipeSection<I, O> {
  BlockPipeSection({this.plumber, this.run});

  final _log = Logger((BlockPipeSection).toString());

  BlockPlumber<I, O>? plumber;

  Future<void> Function()? run;

  final _done = CompleterEx<void>(debugName: 'BlockSection');

  @override
  Future<void> addPlumbing() async {
    await plumber?.call(BlockPlumbing(src.stream.cast<I>(),
        srcErr.stream.cast<I>(), sinkController.sink, sinkErrController.sink));
  }

  @override
  String get debugName => 'block';

  @override
  Future<void> start() async {
    if (run == null) {
      _done.complete();
    } else {
      await run!();

      _log.fine(() => 'block is done');
      _done.complete();
    }

    return _done.future;
  }
}
