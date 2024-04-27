// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import '../half_pipe.dart';
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
  Future<void> start(
    Stream<dynamic> srcIn,
    Stream<dynamic> srcErr,
  ) async {
    await runZonedGuarded(
        () => action(srcIn.cast<I>(), srcErr.cast<I>(), outController.sink,
            errController.sink), (e, st) {
      // TODO(bsutton): what do we do with errors?
    }, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    }));
  }

  @override
  StreamController<O> get errController => StreamController<O>();

  @override
  StreamController<O> get outController => StreamController<O>();
}
