import 'dart:async';
import 'dart:io';

import 'package:dcli_core/dcli_core.dart';
import 'package:dcli_filesystem/dcli_filesystem.dart';

import '../halfpipe.dart';
import 'process_helper.dart';
import 'run_exception.dart';

class RunProcess {
  Future<Process> start({required HalfPipe halfPipe}) async {
    var workingDirectory = halfPipe.workingDirectory;
    workingDirectory ??= Directory.current.path;

    assert(
      !(halfPipe.terminal == true && halfPipe.detached == true),
      'You cannot enable terminal and detached at the same time.',
    );

    var mode =
        halfPipe.detached ? ProcessStartMode.detached : ProcessStartMode.normal;
    if (halfPipe.terminal) {
      mode = ProcessStartMode.inheritStdio;
    }

    var _parsed = halfPipe.parse();

    if (Settings().isWindows && halfPipe.extensionSearch) {
      _parsed.cmd = await searchForCommandExtension(
          _parsed.cmd, halfPipe.workingDirectory);
    }

    if (Settings().isVerbose) {
      final cmdLine = "${_parsed.cmd} ${_parsed.args.join(' ')}";
      verbose(() => 'Process.start: cmdLine $cmdLine');
      verbose(
        () => 'Process.start: runInShell: ${halfPipe.runInShell} '
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
      return await Process.start(
        _parsed.cmd,
        _parsed.args,
        runInShell: halfPipe.runInShell,
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
