// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import '../half_pipe2.dart';
import 'pipe_section.dart';

class ProcessorPipeSection extends PipeSection {
  ProcessorPipeSection(this.action);

  Processor action;

  @override
  Future<void> process(
      Stream<List<String>> stdin, IOSink stdout, IOSink stderr) async {
    await runZonedGuarded(
        () => action(stdoutController.stream, stdout, stderr), (e, st) {},
        zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      stdout.add(line.codeUnits);
    }));
  }
}
