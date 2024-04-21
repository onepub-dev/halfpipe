// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import '../half_pipe2.dart';
import 'pipe_section.dart';

class BlockPipeSection<I, O> extends PipeSection<I, O> {
  BlockPipeSection(this.action);

  Block2<I, O> action;

  @override
  Future<void> start(Stream<List<I>> srcIn, Stream<List<I>> srcErr,
      StreamSink<List<O>> sinkOut, StreamSink<List<O>> sinkErr) async {
    await runZonedGuarded(() => action(srcIn, srcErr, sinkOut, sinkErr),
        (e, st) {
      // TODO(bsutton): what do we do with errors?
    }, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    }));
  }
}
