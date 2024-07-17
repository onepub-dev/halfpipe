// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import '../half_pipe.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class BlockPipeSection<I, O> extends PipeSection<I, O> {
  BlockPipeSection(this.action);

  final _log = Logger((BlockPipeSection).toString());

  Block<I, O> action;

  final _done = CompleterEx<void>(debugName: 'BlockSection');

  @override
  Future<void> get waitUntilOutputDone => _done.future;

  @override
  Future<void> wire(StreamControllerEx<dynamic> srcIn,
      StreamControllerEx<dynamic> srcErr) async {
    // ignore: unawaited_futures
    action(srcIn.stream.cast<I>(), srcErr.stream.cast<I>(), outController.sink,
            errController.sink)
        .then((_) async {
      _log.fine(() => 'block is done');
      _done.complete();
    });
  }

  @override
  String get debugName => 'block';

  @override
  void start() {
    // No Op.
  }
}
