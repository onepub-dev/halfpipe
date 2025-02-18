import 'dart:async';
import 'dart:io';

import 'package:dcli_core/dcli_core.dart' hide RunException;

import 'command_exception.dart';
import 'parse_cli_command.dart';
import 'process_helper.dart';

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
    if (_process == null) {
      throw StateError('You must first call [RunProcess.start]');
    }

    if (terminal) {
      throw StateError(
          '''When `terminal` is true, the process does not have its own stdout but is directly attached to the terminals stdout''');
    }
    return _process!.stdout;
  }

  Stream<List<int>> get stderr {
    if (_process == null) {
      throw StateError('You must first call [RunProcess.start]');
    }
    return _process!.stderr;
  }

  IOSink get stdin {
    if (_process == null) {
      throw StateError('You must first call [RunProcess.start]');
    }

    if (terminal) {
      throw StateError(
          '''When `terminal` is true, the process does not have its own stdin but is directly attached to the terminals stdin''');
    }

    return _process!.stdin;
  }

  Process? _process;

  Future<int> get exitCode {
    if (_process == null) {
      throw StateError('You must first call [RunProcess.start]');
    }

    return _process!.exitCode;
  }

  Future<void> start() async {
    assert(
      !(terminal && detached),
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
      throw CommandException(
        cmdLine,
        -1,
        'The specified workingDirectory [$workingDirectory] does not exist.',
      );
    }
    try {
      _process = await Process.start(
        _parsed.cmd,
        _parsed.args,
        runInShell: runInShell,
        workingDirectory: workingDirectory,
        mode: mode,
        environment: envs,
      );
    } on ProcessException catch (ep, _) {
      if (Platform.isWindows && ep.errorCode == 193) {
        throw CommandException.withArgs(
          ep.executable,
          ep.arguments,
          ep.errorCode,
          '${ep.executable} is not a valid application.',
        );
      }
      if (ep.errorCode == 2) {
        throw CommandException.withArgs(
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
