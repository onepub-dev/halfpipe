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

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

/// The path to the test app - so that unit tests can call us.
final pathToTestApp =
    join(Directory.current.path, 'test', 'src', 'test_app.dart');

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('exit-code', abbr: 'x', defaultsTo: '0', help: 'Exit code')
    ..addOption('stdout-lines',
        abbr: 's', defaultsTo: '0', help: 'Number of lines to write to stdout')
    ..addOption('stderr-lines',
        abbr: 'e', defaultsTo: '0', help: 'Number of lines to write to stderr')
    ..addFlag('stream-stdin',
        abbr: 'i', help: 'Stream stdin and print to stdout');

  final argResults = parser.parse(arguments);

  final exitCode = int.parse(argResults['exit-code'] as String);
  final stdoutLines = int.parse(argResults['stdout-lines'] as String);
  final stderrLines = int.parse(argResults['stderr-lines'] as String);
  final streamStdin = argResults['stream-stdin'] as bool;

  if (streamStdin) {
    stdin
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) {
      stdout.writeln(line);
    }).onDone(() {
      exit(exitCode);
    });
  } else {
    for (var i = 1; i <= stdoutLines; i++) {
      stdout.writeln('$i: This is a line written to stdout');
    }

    for (var i = 1; i <= stderrLines; i++) {
      stderr.writeln('$i: This is a line written to stderr');
    }
    exit(exitCode);
  }
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
