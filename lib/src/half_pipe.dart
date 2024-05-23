// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'pipeline/pipe_phase.dart';
import 'processors/processor.dart';

/// [HalfPipe] allows us to pass through stdout and
/// stderr unlike a bash pipeline that only has one input
/// channel.
/// If a external command is added to the pipeline then
/// only sinkOut and sinkErr will be combined and written
/// to the external commands stdin.
typedef Block<I, O> = Future<void> Function(Stream<I> srcIn, Stream<I> srcErr,
    StreamSink<O> sinkOut, StreamSink<O> sinkErr);

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

  PipePhase<T> block<T>(Block<List<int>, T> callback) =>
      initialPipePhase.block<T>(callback);

  PipePhase<T> processor<T>(Processor<List<int>, T> processor) =>
      initialPipePhase.processor(processor);
}

enum Redirect { toStdout, toStderr, toDevNull }
