// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'pipeline.dart';
import 'pipeline/pipe_phase.dart';
import 'processors/processor.dart';

/// Out [Pipeline] allows us to pass through stdout and
/// stderr unlike a bash pipeline that only has one input
/// channel.
/// If a external command is added to the pipeline then
/// only sinkOut and sinkErr will be combined and written
/// to the external commands stdin.
typedef Block<I, O> = Future<void> Function(
    Stream<List<I>> srcIn,
    Stream<List<I>> srcErr,
    StreamSink<List<O>> sinkOut,
    StreamSink<List<O>> sinkErr);

class HalfPipe2 {
  HalfPipe2() {
    initialPipePhase = PipePhase<int>(this);
  }

  late final PipePhase<int> initialPipePhase;

  PipePhase<int> command(String commandLine,
          {bool runInShell = false,
          bool detached = false,
          bool terminal = false,
          bool extensionSearch = true}) =>
      initialPipePhase.command(commandLine,
          runInShell: runInShell,
          detached: detached,
          terminal: terminal,
          extensionSearch: extensionSearch);

  PipePhase<int> commandAndArgs(String command,
          {List<String>? args,
          bool runInShell = false,
          bool detached = false,
          bool terminal = false,
          bool nothrow = false,
          bool extensionSearch = true,
          String? workingDirectory}) =>
      initialPipePhase.commandAndArgs(command,
          args: args,
          runInShell: runInShell,
          detached: detached,
          terminal: terminal,
          extensionSearch: extensionSearch);

  PipePhase<T> block<T>(Block<int, T> callback) =>
      initialPipePhase.block<T>(callback);

  PipePhase<int> processor(Processor<int> processor) =>
      initialPipePhase.processor(processor);
}

enum Redirect { toStdout, toStderr, toDevNull }
