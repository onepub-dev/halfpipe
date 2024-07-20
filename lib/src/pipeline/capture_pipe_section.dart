// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import 'block_pipe_section.dart';
import 'pipe_section.dart';

/// The same as a BlockPipeSection however all output
/// to print or printerr are captured and sent to the sink
/// controllers of this [PipeSection].
/// Ideally we would like to capture stdout and stderr
/// but I'm not certain this is possible.
class CapturePipeSection<I, O> extends PipeSection<I, O> {
  CapturePipeSection(this.plumber);

  BlockPlumber<I, O> plumber;

  final _done = CompleterEx<void>(debugName: 'CaptureSection');

  @override
  Future<void> addPlumbing() async {
    unawaited(runZonedGuarded(() async {
      await plumber(BlockPlumbing(src.stream.cast<I>(), srcErr.stream.cast<I>(),
          sinkController.sink, sinkErrController.sink));
      _done.complete();
      // ignore: unnecessary_lambdas
    }, (e, st) {
      _done.completeError(e, st);
    }, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    })));
  }

  @override
  String get debugName => 'capture';

  @override
  Future<void> start() async => _done.future;
}
