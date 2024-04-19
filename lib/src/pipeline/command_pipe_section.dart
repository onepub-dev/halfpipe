// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import 'package:dcli_core/dcli_core.dart';

import 'pipe_section.dart';

class CommandPipeSection extends PipeSection {
  CommandPipeSection(this.command,
      {List<String>? args, String? workingDirectory})
      : args = args ?? [],
        workingDirectory = workingDirectory ?? pwd;

  // fields
  String command;
  List<String> args;
  String workingDirectory;

  @override
  @override
  Future<void> process(
      Stream<List<String>> stdin, IOSink stdout, IOSink stderr) async {
    final _fProcess = await Process.start(
      command,
      [...args],
      workingDirectory: pwd,
    );
    // send this [PipeSection] stdin to the spawned
    // processes stdin.
    stdin.listen(_fProcess.stdin);
    await _fProcess.stdout.pipe(stdout);
    await _fProcess.stderr.pipe(stderr);
  }
}
