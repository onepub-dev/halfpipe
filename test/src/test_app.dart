/// An app used by the test suite to simulate different
/// IO and errors.
/// Supports three switches that allows you to control:
/// 1) the exit code
/// 2) the number of lines to output to stdout, each line is prefixed with a number
/// 3) the number of lines to output to stderr, each line is prefixed with a number
library;

import 'dart:io';

import 'package:args/args.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('exit-code', abbr: 'x', defaultsTo: '0', help: 'Exit code')
    ..addOption('stdout-lines',
        abbr: 's', defaultsTo: '0', help: 'Number of lines to write to stdout')
    ..addOption('stderr-lines',
        abbr: 'e', defaultsTo: '0', help: 'Number of lines to write to stderr');

  final argResults = parser.parse(arguments);

  final exitCode = int.parse(argResults['exit-code'] as String);
  final stdoutLines = int.parse(argResults['stdout-lines'] as String);
  final stderrLines = int.parse(argResults['stderr-lines'] as String);

  for (var i = 1; i <= stdoutLines; i++) {
    stdout.writeln('$i: This is a line written to stdout');
  }

  for (var i = 1; i <= stderrLines; i++) {
    stderr.writeln('$i: This is a line written to stderr');
  }

  exit(exitCode);
}
