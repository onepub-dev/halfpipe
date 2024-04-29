// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import '../half_pipe.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

/// The same as a BlockPipeSection however all output
/// to print or printerr are captured and sent to the sink
/// controllers of this [PipeSection].
/// Ideally we would like to capture stdout and stderr
/// but I'm not certain this is possible.
class CapturePipeSection<I, O> extends PipeSection<I, O> {
  CapturePipeSection(this.action);

  Block<I, O> action;

  @override
  Future<CompleterEx<void>> start(
    StreamControllerEx<I> srcIn,
    StreamControllerEx<I> srcErr,
  ) async {
    final completed = CompleterEx<void>(debugName: 'CaptureSection');
    await runZonedGuarded(() async {
      await action(srcIn.stream.cast<I>(), srcErr.stream.cast<I>(),
          outController.sink, errController.sink);
      completed.complete();
      // ignore: unnecessary_lambdas
    }, (e, st) {
      // TODO(bsutton): what do we do with errors?
      completed.completeError(e, st);
    }, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    }));

    return completed;
  }

  @override
  String get debugName => 'capture';
}
