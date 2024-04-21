import 'dart:async';
import 'dart:io';

import 'package:dcli_core/dcli_core.dart' hide RunException;

import 'parse_cli_command.dart';
import 'process_helper.dart';
import 'run_exception.dart';

enum ArgMethod { command, commandAndArgs, commandAndList }

class RunProcess {
  RunProcess.commandLine(String commandLine,
      {required this.runInShell,
      required this.detached,
      required this.terminal,
      required this.nothrow,
      required this.extensionSearch,
      String? workingDirectory})
      : workingDirectory = workingDirectory ?? pwd {
    _parsed = ParsedCliCommand(commandLine, workingDirectory);
  }

  RunProcess.withArgList(String command,
      {required this.runInShell,
      required this.detached,
      required this.terminal,
      required this.nothrow,
      required this.extensionSearch,
      List<String>? args,
      String? workingDirectory})
      : workingDirectory = workingDirectory ?? pwd {
    _parsed =
        ParsedCliCommand.fromArgList(command, args ?? [], workingDirectory);
  }

  String workingDirectory;

  late ParsedCliCommand _parsed;

  bool runInShell;
  bool detached;
  bool terminal;
  bool nothrow;
  bool extensionSearch;

  Stream<List<int>> get stdout {
    if (process == null) {
      throw StateError('You must first call [RunProcess.start]');
    }
    return process!.stdout;
  }

  Stream<List<int>> get stderr {
    if (process == null) {
      throw StateError('You must first call [RunProcess.start]');
    }
    return process!.stderr;
  }

  IOSink get stdin {
    if (process == null) {
      throw StateError('You must first call [RunProcess.start]');
    }
    return process!.stdin;
  }

  Process? process;

  Future<void> start() async {
    assert(
      !(terminal == true && detached == true),
      'You cannot enable terminal and detached at the same time.',
    );

    var mode = detached ? ProcessStartMode.detached : ProcessStartMode.normal;
    if (terminal) {
      mode = ProcessStartMode.inheritStdio;
    }

    if (Settings().isWindows && extensionSearch) {
      _parsed.cmd =
          await searchForCommandExtension(_parsed.cmd, workingDirectory);
    }

    if (Settings().isVerbose) {
      final cmdLine = "${_parsed.cmd} ${_parsed.args.join(' ')}";
      verbose(() => 'Process.start: cmdLine $cmdLine');
      verbose(
        () => 'Process.start: runInShell: $runInShell '
            'workingDir: $workingDirectory mode: $mode '
            'cmd: ${_parsed.cmd} args: ${_parsed.args.join(', ')}',
      );
    }

    if (!exists(workingDirectory)) {
      final cmdLine = "${_parsed.cmd} ${_parsed.args.join(' ')}";
      throw RunException(
        cmdLine,
        -1,
        'The specified workingDirectory [$workingDirectory] does not exist.',
      );
    }
    try {
      process = await Process.start(
        _parsed.cmd,
        _parsed.args,
        runInShell: runInShell,
        workingDirectory: workingDirectory,
        mode: mode,
        environment: envs,
      );
    } on ProcessException catch (ep, _) {
      if (ep.errorCode == 2) {
        throw RunException.withArgs(
          ep.executable,
          ep.arguments,
          ep.errorCode,
          'Could not find ${ep.executable} on the path.',
        );
      }
      rethrow;
    }
  }
}
