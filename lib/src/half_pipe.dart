// ignore_for_file: avoid_returning_this

import 'pipeline/block_pipe_section.dart';
import 'pipeline/pipe_phase.dart';
import 'processors/processor.dart';

/// [HalfPipe] allows us to pass through stdout and
/// stderr unlike a bash pipeline that only has one input
/// channel.
/// If a external command is added to the pipeline then
/// only sinkOut and sinkErr will be combined and written
/// to the external commands stdin.

class HalfPipe {
  HalfPipe() {
    initialPipePhase = PipePhase<List<int>>(this);
  }

  late final PipePhase<List<int>> initialPipePhase;

  PipePhase<List<int>> command(
    String commandLine, {
    bool runInShell = false,
    bool detached = false,
    bool terminal = false,
    bool extensionSearch = true,
    String? workingDirectory,
  }) =>
      initialPipePhase.command(
        commandLine,
        runInShell: runInShell,
        detached: detached,
        terminal: terminal,
        extensionSearch: extensionSearch,
        workingDirectory: workingDirectory,
      );

  PipePhase<List<int>> commandAndArgs(String command,
          {List<String>? args,
          bool runInShell = false,
          bool detached = false,
          bool terminal = false,
          bool nothrow = false,
          bool extensionSearch = true,
          String? workingDirectory}) =>
      initialPipePhase.commandAndArgs(
        command,
        args: args,
        runInShell: runInShell,
        detached: detached,
        terminal: terminal,
        extensionSearch: extensionSearch,
        workingDirectory: workingDirectory,
      );

  PipePhase<O> block<O>(BlockPlumber<List<int>, O> plumber) =>
      initialPipePhase.block<O>(plumber);

  PipePhase<T> processor<T>(Processor<List<int>, T> processor) =>
      initialPipePhase.processor(processor);
}

enum Redirect { toStdout, toStderr, toDevNull }
