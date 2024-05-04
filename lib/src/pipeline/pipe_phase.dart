// ignore_for_file: avoid_returning_this, strict_raw_type

import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:async/async.dart';
import 'package:logging/logging.dart';

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

/// When capturing a list the [CaptureMode] interacts
/// with the maxBuffer setting to control whether
/// we return the first maxBuffer lines [head] or the
/// last maxBuffer lines [tail]
enum CaptureMode { head, tail }

/// Describes the type of data <T> that the pipeline
/// is holding at then end of a [PipeSection].
/// As data move through the pipeline it's type may
/// be translated a number of times.
/// All pipelines start with int data.
class PipePhase<T> {
  PipePhase(this._halfPipe2);

  final HalfPipe _halfPipe2;

  List<PipeSection> sections = [];

  final log = Logger((PipePhase).toString());

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
  PipePhase<O> block<O>(Block<T, O> callback) {
    sections.add(BlockPipeSection<T, O>(callback));

    return _changeType<O>(this);
  }

  ///
  PipePhase<O> processor<O>(Processor<T, O> processor) {
    sections.add(ProcessorPipeSection<T, O>(processor));
    return _changeType<O>(this);
  }

  PipePhase<O> transform<O>(Converter<T, O> converter) {
    sections.add(TransformerPipeSection<T, O>(converter));

    return _changeType<O>(this);
  }

  /// Writes the output stream to the file located at [pathToFile].
  /// The error stream is passed through to the next phase but
  /// not written to the file.
  PipePhase<T> write(String pathToFile) {
    final fileSink = File(pathToFile).openWrite();
    return block<T>((srcIn, srcErr, sinkOut, sinkErr) async {
      srcIn.listen(fileSink.write, onDone: fileSink.close);
      await sinkErr.addStream(srcErr);
    });
  }

  /// redirect the processors output
  PipePhase<T> redirectStdout(Redirect redirect) => this;
  PipePhase<T> redirectStderr(Redirect redirect) => this;

  //////////////////////////////////////////////////////
  // The following are terminal functions
  // After they are called no additional sections
  // can be added to the pipeline.
  // A terminal function runs the pipeline.
  //////////////////////////////////////////////////////

  /// Runs the pipeline outputing the results to a list
  /// capturing both out and err and mixing the two into
  /// the list in the order they are output.
  /// If the list exceeds [maxBuffer] then any further
  /// data will be dropped - so essentially a 'head' command.
  /// Runs the pipeline outputting the results to a list.
  Future<List<T>> toList(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.head,
      bool captureOut = true,
      bool captureErr = true}) async {
    final list = await toMix(
        maxBuffer: maxBuffer, captureErr: false, captureMode: captureMode);
    return list;
  }

  /// Returns the 'out' stream and the 'err' stream
  /// as two separate lists.
  /// Each list can hold up to [maxBuffer] elements.
  /// The [captureMode] controls whether the fist [maxBuffer] elements (head)
  /// or the last [maxBuffer] elements (tail) are returned.
  Future<Lists<T>> toLists(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.tail,
      bool captureOut = true,
      bool captureErr = true}) async {
    final lists = Lists<T>();

    if (captureOut) {
      _capture(sinkOutController, lists.out, maxBuffer, captureMode);
    }

    if (captureErr) {
      _capture(sinkOutController, lists.err, maxBuffer, captureMode);
    }

    /// run the pipeline.
    await run();
    return lists;
  }

  /// Returns a single list that mixes out and err in the
  /// order that they are output from the pipeline.
  Future<List<T>> toMix(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.tail,
      bool captureOut = true,
      bool captureErr = true}) async {
    final list = <T>[];

    if (captureOut) {
      _capture(sinkOutController, list, maxBuffer, captureMode);
    }

    if (captureErr) {
      _capture(sinkOutController, list, maxBuffer, captureMode);
    }

    /// run the pipeline.
    await run();
    return list;
  }

  // captures data from the [controller]'s stram placing it in the [list]
  void _capture(StreamControllerEx<T> controller, List<T> list, int maxBuffer,
      CaptureMode captureMode) {
    final stream = controller.stream;
    stream.cast<T>().listen((data) {
      if (list.length < maxBuffer) {
        list.add(data);
      } else {
        if (captureMode == CaptureMode.tail) {
          list
            ..removeAt(0)
            ..add(data);
        }
      }
    });
  }

  // TODO: what does it mean to run toList and then want to get a non-zero exitcode.
  // can we do both. Seams a problem as to List returns a list.
  // We have scenarios such as docker buildex which returns the id
  // via stdout but general logging is via stderr.
  // So in the case we need to gret a list from stderr, one line from stdout
  // and the exit code to ensure that everything worked.

  // This suggest that we need a double headed toList command that
  // provides stdout and stderr as separate lists

  /// Runs the pipeline returning the last [n] lines of the output.
  /// If you choose to capture err and out then they are mixed in the
  /// list in the order the pipeline outputs them.
  Future<List<T>> tail(int n,
          {bool captureOut = true, bool captureErr = false}) async =>
      toMix(maxBuffer: n, captureErr: captureErr, captureOut: captureOut);

  /// Runs the pipeline returning the fist [n] lines of the output.
  /// This is actually the default mode of [toList] but we include
  /// this method for symmetry with the tail method.
  Future<List<T>> head(int n,
          {bool captureOut = true, bool captureErr = false}) async =>
      toMix(
          maxBuffer: n,
          captureErr: captureErr,
          captureOut: captureOut,
          captureMode: CaptureMode.head);

  /// Runs the pipeline outputing the results to a paragraph of
  /// text containing newlines.
  /// If the list exceeds [maxBuffer] then any further
  /// data will be dropped.
  /// The [captureMode] controls whether we return the first [maxBuffer]
  /// lines (head) or the last [maxBuffer] lines (tail).
  Future<String> toParagraph(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.head}) async {
    final list = await toList(maxBuffer: maxBuffer, captureMode: captureMode);
    return list.join('\n');
  }

  /// Runs the pipeline printing stdout and stderr
  /// to the console.
  /// If the streams are a List<int> we automatically
  /// convert it to a List<String>
  Future<void> printmix(
      {bool showStdout = true, bool showStderr = true}) async {
    if (T == List<int>) {
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

  /// The output of the final phase is funnelled into
  /// these two controllers.
  StreamControllerEx<T> sinkOutController =
      StreamControllerEx<T>(debugName: 'final: out');
  StreamControllerEx<T> sinkErrController =
      StreamControllerEx<T>(debugName: 'final err');

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
          .listen((data) => sinkOutController.add(data as T));
      priorErrController.stream
          .listen((data) => sinkErrController.add(data as T));

      for (var i = 0; i < sections.length; i++) {
        final section = sections[i];
        log.fine(() => 'waiting for section: ${section.debugName} to complete');
        await section.done.future;
        log.fine(() => 'closing section ${section.debugName}');
        await section.close();
      }
      // await sub.cancel();
      await stdinController.close();
    });
  }

  PipePhase<O> _changeType<O>(PipePhase<T> src) {
    final out = PipePhase<O>(src._halfPipe2)..sections = src.sections;
    return out;
  }

  Stream<List<T>> get stdout => sinkOutController.stream as Stream<List<T>>;
  Stream<List<T>> get stderr => sinkErrController.stream as Stream<List<T>>;

  Future<Stream<core.List<T>>> get stdmix async => mixStreams(stdout, stderr);
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

class Terminal {
  // TODO(bsutton): fix this
  int get exitCode => 0;
}

class Lists<T> {
  List<T> out = <T>[];
  List<T> err = <T>[];
}
