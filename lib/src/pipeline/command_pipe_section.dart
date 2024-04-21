// ignore_for_file: avoid_returning_this

import 'dart:async';

import '../run_process.dart';
import 'pipe_section.dart';

class CommandPipeSection extends PipeSection<String, String> {
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
  final Completer<bool> _stdoutFlushed = Completer<bool>();
  final Completer<bool> _stderrFlushed = Completer<bool>();

  int? exitCode;

  @override
  Future<void> start(
      Stream<List<dynamic>> srcIn,
      Stream<List<dynamic>> srcErr,
      StreamSink<List<dynamic>> sinkOut,
      StreamSink<List<dynamic>> sinkErr) async {
    /// Feed data from the prior [PipeSection] into
    /// our running process.
    srcIn.listen((line) => runProcess.stdin.write(line));
    srcErr.listen((line) => runProcess.stdin.write(line));
    await runProcess.start();

    /// Feed data from our running process to the next [PipeSection].
    runProcess.stdout
        // .transform(utf8.decoder)
        // .transform(const LineSplitter())
        .listen((data) {
      sinkOut.add(data);
    }).onDone(() => _stdoutFlushed.complete(true));

    runProcess.stderr
        // .transform(utf8.decoder)
        // .transform(const LineSplitter())
        .listen((data) {
      sinkErr.add(data);
    }).onDone(() => _stderrFlushed.complete(true));

    exitCode = await runProcess.exitCode;
  }
}
