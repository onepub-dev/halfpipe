// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import '../run_process.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

abstract class HasExitCode {
  int get exitCode;
}

class CommandPipeSection extends PipeSection<List<int>, List<int>>
    implements HasExitCode {
  CommandPipeSection.commandLine(String commandLine,
      {bool runInShell = false,
      bool detached = false,
      bool terminal = false,
      bool nothrow = false,
      bool extensionSearch = false,
      String? workingDirectory})
      : runProcess = RunProcess.commandLine(commandLine,
            runInShell: runInShell,
            detached: detached,
            terminal: terminal,
            nothrow: nothrow,
            extensionSearch: extensionSearch,
            workingDirectory: workingDirectory);

  CommandPipeSection.withArgList(String command,
      {bool runInShell = false,
      bool detached = false,
      bool terminal = false,
      bool nothrow = false,
      bool extensionSearch = false,
      List<String>? args,
      String? workingDirectory})
      : runProcess = RunProcess.withArgList(command,
            args: args,
            runInShell: runInShell,
            detached: detached,
            terminal: terminal,
            nothrow: nothrow,
            extensionSearch: extensionSearch,
            workingDirectory: workingDirectory);

  final _log = Logger((CommandPipeSection).toString());

  RunProcess runProcess;

  @override
  late final int exitCode;

  // If we wait now then we stop the next stage in the pipeline
  // from running.
  // exitCode = await runProcess.exitCode;
  @override
  final done = CompleterEx<void>(debugName: 'CommandPipe: done');

  @override
  Future<void> start(
    StreamControllerEx<dynamic> srcIn,
    StreamControllerEx<dynamic> srcErr,
  ) async {
    /// Feed data from the prior [PipeSection] into
    /// our running process.
    srcIn.stream.listen((line) => runProcess.stdin.write(line));
    srcErr.stream.listen((line) => runProcess.stdin.write(line));
    try {
      await runProcess.start();

      final _stdoutFlushed =
          CompleterEx<void>(debugName: 'CommandSection - stdout');

      /// Feed data from our running process to the next [PipeSection].
      runProcess.stdout.listen((data) {
        _log.fine(() => 'process: sending data: ${data.length}');
        outController.sink.add(data);
      }).onDone(() async {
        _log.fine(() => 'Command: done - out');
        _stdoutFlushed.complete();
      });

      final _stderrFlushed =
          CompleterEx<void>(debugName: 'CommandSection - stderr');
      runProcess.stderr.listen(errController.add).onDone(() async {
        _stderrFlushed.complete();
      });

      unawaited(Future.wait<void>([
        _stdoutFlushed.future,
        _stderrFlushed.future,
        runProcess.exitCode
      ]).then((value) async {
        exitCode = await runProcess.exitCode;
        done.complete();
      }));
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      done.completeError(e);
    }
  }

  @override
  String get debugName => 'command';
}
