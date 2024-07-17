// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import '../command_exception.dart';
import '../run_process.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

abstract class HasExitCode {
  int get exitCode;
}

enum _StartType { runWithArgs, runWithCommandLine }

class CommandPipeSection extends PipeSection<List<int>, List<int>>
    implements HasExitCode {
  CommandPipeSection.commandLine(String commandLine,
      {bool runInShell = false,
      bool detached = false,
      bool terminal = false,
      this.nothrow = false,
      bool extensionSearch = false,
      String? workingDirectory})
      : _startType = _StartType.runWithCommandLine,
        _commandLine = commandLine,
        runProcess = RunProcess.commandLine(commandLine,
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
      this.nothrow = false,
      bool extensionSearch = false,
      List<String>? args,
      String? workingDirectory})
      : _startType = _StartType.runWithArgs,
        _command = command,
        _args = args,
        runProcess = RunProcess.withArgList(command,
            args: args,
            runInShell: runInShell,
            detached: detached,
            terminal: terminal,
            nothrow: nothrow,
            extensionSearch: extensionSearch,
            workingDirectory: workingDirectory);

  final _log = Logger((CommandPipeSection).toString());

  RunProcess runProcess;

  final bool nothrow;

  final _StartType _startType;

  String? _commandLine;
  String? _command;
  List<String>? _args;

  @override
  late final int exitCode;

  /// Used to flag that that this pipe section has completed.
  final _done = CompleterEx<void>(debugName: 'CommandPipe: done');

  @override
  Future<void> get waitUntilOutputDone => _done.future;

  late final StreamControllerEx<dynamic> srcIn;
  late final StreamControllerEx<dynamic> srcErr;

  final _stdoutFlushed =
      CompleterEx<void>(debugName: 'CommandSection - stdout');
  final _stderrFlushed =
      CompleterEx<void>(debugName: 'CommandSection - stderr');

  @override
  Future<void> wire(
    StreamControllerEx<dynamic> srcIn,
    StreamControllerEx<dynamic> srcErr,
  ) async {
    this.srcIn = srcIn;
    this.srcErr = srcErr;

    /// Feed data from the prior [PipeSection] into
    /// our running process.
    srcIn.stream.listen((line) => runProcess.stdin.write(line));
    srcErr.stream.listen((line) => runProcess.stdin.write(line));

    //
  }

  @override
  Future<void> start() async {
    try {
      await runProcess.start();

      // Feed data from our running process to the next [PipeSection].
      runProcess.stdout.listen((data) {
        _log.fine(() => 'process: sending data: ${data.length}');
        outController.sink.add(data);
      }).onDone(() async {
        _log.fine(() => 'Command: done - out');
        _stdoutFlushed.complete();
      });

      /// Listen the error stream until it is done
      /// so we can wait for the stream to be flushed before
      /// we fully shutdown.
      runProcess.stderr.listen(errController.add).onDone(() async {
        _stderrFlushed.complete();
      });

      unawaited(Future.wait<void>([
        _stdoutFlushed.future,
        _stderrFlushed.future,
        runProcess.exitCode
      ]).then((value) async {
        exitCode = await runProcess.exitCode;

        if (exitCode == 0 || nothrow == true) {
          _done.complete();
        } else {
          if (_startType == _StartType.runWithArgs) {
            _done.completeError(CommandException.withArgs(_command, _args ?? [],
                exitCode, 'The command exited with a non-zero exit code.'));
          } else {
            _done.completeError(CommandException(_commandLine!, exitCode,
                'The command exited with a non-zero exit code.'));
          }
        }
      }));

      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _done.completeError(e);
    }
  }

  @override
  String get debugName => 'command';
}
