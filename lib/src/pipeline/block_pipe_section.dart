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
  Future<void> start(Stream<dynamic> srcIn, Stream<dynamic> srcErr) async {
    final done = CompleterEx<void>();
    // ignore: unawaited_futures
    action(srcIn.cast<I>(), srcErr.cast<I>(), _outController.sink,
            _errController.sink)
        .then((_) async {
      done.complete();
      await _errController.close();
      await _outController.close();
    });

    return done.future;
  }

  late final _errController = StreamControllerEx<O>(debugName: 'block: err');
  late final _outController = StreamControllerEx<O>(debugName: 'block: out');

  @override
  StreamControllerEx<O> get errController => _errController;

  @override
  StreamControllerEx<O> get outController => _outController;
}
