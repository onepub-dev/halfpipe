/// An app used by the test suite to simulate different
/// IO and errors.
/// Supports three switches that allows you to control:
/// 1) the exit code
/// 2) the number of lines to output to stdout, each line is prefixed
///   with a number
/// 3) the number of lines to output to stderr, each line is prefixed
///    with a number
// ignore_for_file: unreachable_from_main

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:completer_ex/completer_ex.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

/// The path to the test app - so that unit tests can call us.
final pathToTestApp =
    join(Directory.current.path, 'test', 'src', 'test_app.dart');
final pathToLogger =
    join(DartProject.self.pathToProjectRoot, 'test', 'logger.txt');

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('exit-code', abbr: 'x', defaultsTo: '0', help: 'Exit code')
    ..addOption('stdout-lines',
        abbr: 's', defaultsTo: '0', help: 'Number of lines to write to stdout')
    ..addOption('stderr-lines',
        abbr: 'e', defaultsTo: '0', help: 'Number of lines to write to stderr')
    ..addFlag('stream-stdin',
        abbr: 'i',
        help:
            '''Stream stdin and print to stdout until a single line with 'quit' is seen in stdin''');

  pathToLogger.write('test_app: starting 1');
  final argResults = parser.parse(arguments);

  final exitCode = int.parse(argResults['exit-code'] as String);
  final stdoutLines = int.parse(argResults['stdout-lines'] as String);
  final stderrLines = int.parse(argResults['stderr-lines'] as String);
  final streamStdin = argResults['stream-stdin'] as bool;

  if (streamStdin) {
    await _streamStdin();
    exitNow(exitCode);
  } else {
    for (var i = 1; i <= stdoutLines; i++) {
      stdout.writeln('$i: This is a line written to stdout');
    }

    for (var i = 1; i <= stderrLines; i++) {
      stderr.writeln('$i: This is a line written to stderr');
    }
  }
  exitNow(exitCode);
}

void exitNow(int exitCode) {
  pathToLogger.append('test_app: exiting $exitCode');
  exit(exitCode);
}

/// Builds a command line to run this test app.
String buildTestAppCommand(
    {int exitCode = 0,
    int outLines = 0,
    int errLines = 0,
    bool streamStdin = false}) {
  final sb = StringBuffer()
    ..write('dart ')
    ..write(pathToTestApp)
    ..write(' --exit-code $exitCode');
  if (streamStdin) {
    sb.write(' --stream-stdin');
  } else {
    sb
      ..write(' --stdout-lines $outLines')
      ..write(' --stderr-lines $errLines');
  }
  return sb.toString();
}

Future<void> _streamStdin() async {
  final exitSeen = CompleterEx<void>();

  final controller = StreamController<List<int>>();

  // Listen to stdin and forward data to the controller
  // so that we can exit when we see 'exit' in the stream.
  stdin
      // .transform(utf8.decoder)
      // .transform(const LineSplitter())
      .listen((line) async {
    pathToLogger.append('test_app $line');

    controller.add(line);
  }, onError: (e) {
    pathToLogger.append('test_app: streamStdin error $e');
  }, onDone: () {
    pathToLogger.append('test_app: streamStdin done');
  });

  // Listen to the custom stream
  controller.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
    (line) async {
      if (line != 'quit') {
        stdout.writeln(line);
        pathToLogger.append('test_app(2nd) $line');
      } else {
        pathToLogger.append('test_app(2nd) quitting');
        await controller.close();
      }
    },
    onDone: exitSeen.complete,
  );

  Future.delayed(const Duration(seconds: 60), () {
    pathToLogger.append('test_app: streamStdin timed out');
    exitSeen.complete();
  });

  await exitSeen.future;
  pathToLogger.append('test_app: streamStdin done');
}
