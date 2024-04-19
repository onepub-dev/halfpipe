// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

abstract class PipeSection {
  PipeSection() {
    stdout = stdoutController.sink;
    stderr = stderrController.sink;
  }

  Future<void> process(
      Stream<List<String>> stdin, IOSink stdout, IOSink stderr);

  /// Each PipeSection is wired to the next and previous [PipeSection]
  /// via streams.

  /// input from the prior pipe-section
  late final stdinController = StreamController<List<String>>();
  late final StreamSubscription<List<String>> stdin;

  /// send data to stdout
  late final stdoutController = StreamController<List<String>>();
  late final StreamSink<List<String>> stdout;

  /// send data to stderr
  late final stderrController = StreamController<List<String>>();
  late final StreamSink<List<String>> stderr;

  Future<void> close() async {
    await stdinController.close();
    await stdoutController.close();
    await stderrController.close();

    await stdout.close();
    await stderr.close();
  }
}
