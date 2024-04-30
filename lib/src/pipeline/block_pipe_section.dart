// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../half_pipe.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class BlockPipeSection<I, O> extends PipeSection<I, O> {
  BlockPipeSection(this.action);

  Block<I, O> action;

  @override
  final done = CompleterEx<void>(debugName: 'BlockSection');

  @override
  Future<void> start(StreamControllerEx<dynamic> srcIn,
      StreamControllerEx<dynamic> srcErr) async {
    // ignore: unawaited_futures
    action(srcIn.stream.cast<I>(), srcErr.stream.cast<I>(), outController.sink,
            errController.sink)
        .then((_) async {
      done.complete();
    });
  }

  @override
  String get debugName => 'block';
}
