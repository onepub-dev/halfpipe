// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import '../half_pipe.dart';
import 'pipe_section.dart';

class BlockPipeSection<I, O> extends PipeSection<I, O> {
  BlockPipeSection(this.action);

  Block<I, O> action;

  @override
  Future<void> start(Stream<dynamic> srcIn, Stream<dynamic> srcErr,
      StreamSink<O> sinkOut, StreamSink<O> sinkErr) async {
    await runZonedGuarded(
        () => action(srcIn.cast<I>(), srcErr.cast<I>(), sinkOut, sinkErr),
        (e, st) {
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
