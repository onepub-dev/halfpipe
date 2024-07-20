// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';
import 'package:logging/logging.dart';

import '../command_exception.dart';
import '../run_process.dart';
import 'pipe_section.dart';

abstract class HasExitCode {
  int get exitCode;
}

enum _StartType { runWithArgs, runWithCommandLine }

class CommandPipeSection<I> extends PipeSection<I, List<int>>
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

  final _stdoutFlushed =
      CompleterEx<void>(debugName: 'CommandSection - stdout');
  final _stderrFlushed =
      CompleterEx<void>(debugName: 'CommandSection - stderr');

  final _started = CompleterEx<void>(debugName: 'CommandSection - started');
  @override
  Future<void> addPlumbing() async {
    /// Feed data from the prior [PipeSection] into
    /// our running process.
    src.stream.listen((data) async {
      try {
        _log.fine(() => 'command src recieved: $data');

        /// Make certain we don't write to stdin until the
        /// process has started.
        await _started.future;

        /// Write the data to stdin
        if (data is List<int>) {
          runProcess.stdin.add(data as List<int>);
        } else {
          /// convert data to a string and the send it to stdin
          runProcess.stdin.write(data);
        }
        _log.fine(() => 'command src sent to app: $data');
        // ignore: avoid_catches_without_on_clauses
      } catch (e, st) {
        _log.severe('Error writing to stdin', e, st);
      }
    });
    srcErr.stream.listen((data) {
      _log.fine(() => 'command srcErr recieved: $data');
      runProcess.stdin.write(data);
    });
  }

  @override
  Future<void> start() async {
    try {
      _log.fine(() => 'starting $_commandLine');
      await runProcess.start();
      _log.fine(() => 'started $_commandLine');

      // Feed data from our running process to the next [PipeSection].
      runProcess.stdout.listen((data) {
        _log.fine(() => 'command stdout recieved: $data');
        sinkController.sink.add(data);
      }).onDone(() async {
        _log.fine(() => 'Command: done - out');
        _stdoutFlushed.complete();
      });

      /// Listen the error stream until it is done
      /// so we can wait for the stream to be flushed before
      /// we fully shutdown.
      runProcess.stderr.listen(sinkErrController.add).onDone(() async {
        _stderrFlushed.complete();
      });

      /// Now the app has started and the streams are all
      /// wired allow data to flow into the spawned up.
      _started.complete();

      unawaited(Future.wait<void>([
        _stdoutFlushed.future,
        _stderrFlushed.future,
        runProcess.exitCode
      ]).then((value) async {
        exitCode = await runProcess.exitCode;

        if (exitCode == 0 || nothrow) {
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
    return _done.future;
  }

  @override
  String get debugName => 'command';
}
