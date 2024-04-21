// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import '../half_pipe2.dart';
import 'pipe_section.dart';

class BlockPipeSection<I, O> extends PipeSection<I, O> {
  BlockPipeSection(this.action);

  Block<I, O> action;

  @override
  Future<void> start(
      Stream<List<dynamic>> srcIn,
      Stream<List<dynamic>> srcErr,
      StreamSink<List<dynamic>> sinkOut,
      StreamSink<List<dynamic>> sinkErr) async {
    await runZonedGuarded(
        () => action(
            srcIn.cast<List<I>>(),
            srcErr.cast<List<I>>(),
            sinkOut as StreamSink<List<O>>,
            sinkErr as StreamSink<List<O>>), (e, st) {
      // TODO(bsutton): what do we do with errors?
    }, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    }));
  }
}
