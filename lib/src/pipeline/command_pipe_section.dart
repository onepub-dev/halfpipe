// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../run_process.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class CommandPipeSection extends PipeSection<List<int>, List<int>> {
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

  RunProcess runProcess;

  int? exitCode;

  @override
  Future<void> start(
    Stream<dynamic> srcIn,
    Stream<dynamic> srcErr,
  ) async {
    /// Feed data from the prior [PipeSection] into
    /// our running process.
    srcIn.listen((line) => runProcess.stdin.write(line));
    srcErr.listen((line) => runProcess.stdin.write(line));
    await runProcess.start();

    final _stdoutFlushed = CompleterEx<bool>();

    /// Feed data from our running process to the next [PipeSection].
    runProcess.stdout.listen((data) {
      print('process: sending data: ${data.length}');
      outController.add(data);
    }).onDone(() async {
      _stdoutFlushed.complete(true);
      await outController.close();
    });

    final _stderrFlushed = CompleterEx<bool>();
    runProcess.stderr.listen(errController.add).onDone(() async {
      _stderrFlushed.complete(true);
      await errController.close();
    });

    // If we wait now then we stop the next stage in the pipeline
    // from running.
    // exitCode = await runProcess.exitCode;
    final done = Completer<void>();

    unawaited(Future.wait<void>(
            [_stdoutFlushed.future, _stderrFlushed.future, runProcess.exitCode])
        .then((value) {
      done.complete();
    }));

    /// when all the streams are flushed and the process has exited.
    return done.future;
  }

  @override
  StreamControllerEx<List<int>> get errController =>
      StreamControllerEx<List<int>>(debugName: 'command: err');

  @override
  StreamControllerEx<List<int>> get outController =>
      StreamControllerEx<List<int>>(debugName: 'command: out');
}
