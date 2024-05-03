// ignore_for_file: avoid_returning_this, strict_raw_type

import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:async/async.dart';

import '../half_pipe.dart';
import '../processors/processor.dart';
import '../transformers/transform.dart';
import '../util/stream_controller_ex.dart';
import 'block_pipe_section.dart';
import 'command_pipe_section.dart';
import 'pipe_section.dart';
import 'processor_pipe_section.dart';
import 'stdin_wrapper.dart';
import 'transformer_pipe_section.dart';

/// Describes the type of data <T> that the pipeline
/// is holding at then end of a [PipeSection].
/// As data move through the pipeline it's type may
/// be translated a number of times.
/// All pipelines start with int data.
class PipePhase<I> {
  PipePhase(this._halfPipe2);

  final HalfPipe _halfPipe2;

  List<PipeSection> sections = [];

  PipePhase<List<int>> command(String commandLine,
      {bool runInShell = false,
      bool detached = false,
      bool terminal = false,
      bool extensionSearch = true,
      String? workingDirectory}) {
    sections.add(CommandPipeSection.commandLine(commandLine,
        runInShell: runInShell,
        detached: detached,
        terminal: terminal,
        extensionSearch: extensionSearch,
        workingDirectory: workingDirectory));
    return _changeType<List<int>>(this);
  }

  PipePhase<int> commandAndArgs(String command,
      {List<String>? args,
      bool runInShell = false,
      bool detached = false,
      bool terminal = false,
      bool nothrow = false,
      bool extensionSearch = true,
      String? workingDirectory}) {
    sections.add(CommandPipeSection.withArgList(command,
        args: args,
        runInShell: runInShell,
        detached: detached,
        terminal: terminal,
        nothrow: nothrow,
        extensionSearch: extensionSearch,
        workingDirectory: workingDirectory));
    return _changeType<int>(this);
  }

  /// Defines a block of dart code that can is called as
  /// part of the pipeline.
  PipePhase<O> block<O>(Block<I, O> callback) {
    sections.add(BlockPipeSection<I, O>(callback));

    return _changeType<O>(this);
  }

  ///
  PipePhase<O> processor<O>(Processor<I, O> processor) {
    sections.add(ProcessorPipeSection<I, O>(processor));
    return _changeType<O>(this);
  }

  PipePhase<O> transform<O>(Converter<I, O> converter) {
    sections.add(TransformerPipeSection<I, O>(converter));

    return _changeType<O>(this);
  }

  /// Writes the output stream to the file located at [pathToFile].
  /// The error stream is passed through to the next phase but
  /// not written to the file.
  PipePhase<I> write(String pathToFile) {
    final fileSink = File(pathToFile).openWrite();
    return block<I>((srcIn, srcErr, sinkOut, sinkErr) async {
      srcIn.listen(fileSink.write, onDone: fileSink.close);
      await sinkErr.addStream(srcErr);
    });
  }

  /// redirect the processors output
  PipePhase<I> redirectStdout(Redirect redirect) => this;
  PipePhase<I> redirectStderr(Redirect redirect) => this;

  //////////////////////////////////////////////////////
  // The following are terminal functions
  // After they are called no additional sections
  // can be added to the pipeline.
  // A terminal function runs the pipeline.
  //////////////////////////////////////////////////////

  /// Runs the pipeline outputing the results to a list.
  /// If the list exceeds [maxBuffer] then any further
  /// data will be dropped.
  /// Runs the pipeline outputting the results to a list.
  Future<List<I>> toList([int maxBuffer = 10000]) async {
    final elements = <I>[];

    sinkOutController.stream.cast<I>().listen((data) {
      if (elements.length < maxBuffer) {
        elements.add(data);
      }
    });

    /// run the pipeline.
    await run();
    return elements;
  }

  /// Runs the pipeline returning the last [n] lines of the output.
  Future<List<I>> tail(int n) async {
    final elements = <I>[];

    sinkOutController.stream.cast<I>().listen((data) {
      if (elements.length >= n) {
        elements.removeAt(0); // Remove the oldest element
      }
      elements.add(data); // Add the new data
    });

    /// run the pipeline.
    await run();
    return elements;
  }

  /// Runs the pipeline outputing the results to a paragraph of
  /// text containing newlines.
  /// If the list exceeds [maxBuffer] then any further
  /// data will be dropped
  Future<String> toParagraph([int maxBuffer = 10000]) async {
    final list = await toList(maxBuffer);
    return list.join('\n');
  }

  /// Runs the pipeline printing stdout and stderr
  /// to the console.
  /// If the streams are a List<int> we automatically
  /// convert it to a List<String>
  Future<void> printmix(
      {bool showStdout = true, bool showStderr = true}) async {
    if (I == List<int>) {
      sections.add(TransformerPipeSection<List<int>, String>(Transform.line));
    }

    sections.add(BlockPipeSection(
      (srcIn, srcErr, sinkOut, sinkErr) async {
        if (showStdout) {
          srcIn.listen(core.print);
        }
        if (showStderr) {
          srcErr.listen(core.print);
        }
      },
    ));

    await run();
  }

  /// Runs the pipeline printing the output stream to stdout.
  /// If the stream is a List<int> we automatically
  /// convert it to a List<String>
  /// The error stream is supressed.
  Future<void> print() async {
    await printmix(showStderr: false);
  }

  /// Runs the pipeline printing the error stream to stdout.
  /// If the stream is a List<int> we automatically
  /// convert it to a List<String>
  /// The output stream is supressed.
  Future<void> printerr() async {
    await printmix(showStdout: false);
  }

  // TODO(bsutton): fix this
  Future<int> exitCode() async => 1;

  /// The output of the final phase is funnelled into
  /// these two controllers.
  StreamControllerEx<I> sinkOutController =
      StreamControllerEx<I>(debugName: 'final: out');
  StreamControllerEx<I> sinkErrController =
      StreamControllerEx<I>(debugName: 'final err');

  // Wire up the [PipeSection]s by attaching their streams
  // and then run the pipeline.
  Future<void> run() async {
    await withStdin(debugName: 'stdin of main process',
        (stdinController) async {
      // final sub = stdinController.stream
      //     .listen((data) => stdinController.sink.add(data));

      /// Wire the process's stdin as the first
      /// section's input
      StreamControllerEx<dynamic> priorOutController = stdinController;

      /// The first section has no error inputs so wire in
      /// an empty stream.
      StreamControllerEx<dynamic> priorErrController =
          StreamControllerEx<List<int>>(
              debugName: 'dummy stdin - error channel');

      // final sectionCompleters = <CompleterEx<void>>[];

      for (final section in sections) {
        section.start(
          priorOutController,
          priorErrController,
        );

        priorOutController = section.outController;
        priorErrController = section.errController;
      }

      priorOutController.stream
          .listen((data) => sinkOutController.add(data as I));
      priorErrController.stream
          .listen((data) => sinkErrController.add(data as I));

      for (var i = 0; i < sections.length; i++) {
        final section = sections[i];
        core.print('waiting for section: ${section.debugName} to complete');
        await section.done.future;
        core.print('closing section ${section.debugName}');
        await section.close();
      }
      // await sub.cancel();
      await stdinController.close();
    });
  }

  PipePhase<O> _changeType<O>(PipePhase<I> src) {
    final out = PipePhase<O>(src._halfPipe2)..sections = src.sections;
    return out;
  }

  Stream<List<I>> get stdout => sinkOutController.stream as Stream<List<I>>;
  Stream<List<I>> get stderr => sinkErrController.stream as Stream<List<I>>;

  Future<Stream<core.List<I>>> get stdmix async => mixStreams(stdout, stderr);
// Function to mix two streams
  Future<Stream<S>> mixStreams<S>(Stream<S> stream1, Stream<S> stream2) async {
    // Create a StreamGroup
    final group = StreamGroup<S>();

    // Add both streams to the StreamGroup
    await group.add(stream1);
    await group.add(stream2);

    // TODO(bsutton): not certian if this is correct.
    await group.close();

    // Return the combined stream from the StreamGroup
    return group.stream;
  }

  Future<void> main() async {
    // Example streams
    final stream1 = Stream.fromIterable([1, 3, 5]);
    final stream2 = Stream.fromIterable([2, 4, 6]);

    // Mix the streams
    final mixedStream = await mixStreams(stream1, stream2);

    // Listen to the mixed stream
    mixedStream.listen(core.print);
  }
}
