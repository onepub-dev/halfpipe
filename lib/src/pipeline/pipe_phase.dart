// ignore_for_file: avoid_returning_this, strict_raw_type

import 'dart:async';
import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io' as io;

import 'package:async/async.dart';
import 'package:logging/logging.dart';

import '../half_pipe.dart';
import '../processors/processor.dart';
import '../transformers/transform.dart';
import '../util/stream_controller_ex.dart';
import 'block_pipe_section.dart';
import 'capture.dart';
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

  PipePhase<List<int>> commandAndArgs(String command,
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
    return _changeType<List<int>>(this);
  }

  /// Defines a block of dart code that is called as
  /// part of the pipeline.
  /// ```dart
  ///  await HalfPipe()
  ///      .processor(DirectoryList('*.*', workingDirectory: rootPath))
  ///      .block<String>((srcIn, srcErr, stdout, stderr) async {
  ///    await for (final line in srcIn) {
  ///      _log.fine(() => 'Found: $line');
  ///    }
  ///  }).exitCode();
  /// ```

  PipePhase<O> block<O>(BlockPlumber<T, O> plumber,
      [Future<void> Function()? run]) {
    sections.add(BlockPipeSection<T, O>(plumber: plumber, run: run));

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
  PipePhase<T> writeToFile(String pathToFile) {
    final fileSink = io.File(pathToFile).openWrite();
    return block<T>((plumbing) async {
      plumbing.src.listen(fileSink.write, onDone: fileSink.close);
      await plumbing.sinkErr.addStream(plumbing.srcErr);
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
  Future<CaptureMixed<T>> captureMixed(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.head,
      bool captureOut = true,
      bool captureErr = true}) async {
    final capture = CaptureMixed<T>();

    if (captureOut) {
      _capture(sinkOutController, capture.mixed, maxBuffer, captureMode);
    }

    if (captureErr) {
      _capture(sinkErrController, capture.mixed, maxBuffer, captureMode);
    }

    /// run the pipeline.
    capture.exitCode = await _run();
    return capture;
  }

  Future<CaptureNone<T>> captureNone() async {
    final exitCode = await _run();

    return CaptureNone<T>(exitCode);
  }

  /// Runs the pipeline. Any output written to stdout or
  /// stderr will be let through to the terminal.
  /// If one or more of the [PipeSection] implements [HasExitCode]
  /// the exitCode of the last [HasExitCode] section is returned otherwise
  /// 0 is returned.
  core.Future<core.int> exitCode() async => _run();

  /// Returns the 'out' stream and the 'err' stream
  /// as two separate lists.
  /// Each list can hold up to [maxBuffer] elements.
  /// If one or more of the [PipeSection] implements [HasExitCode]
  /// the exitCode of the last [HasExitCode] section is available in the
  /// [CaptureBoth] otherwise the exitCode is set to zero.
  /// The [captureMode] controls whether the fist [maxBuffer] elements (head)
  /// or the last [maxBuffer] elements (tail) are returned.
  Future<CaptureBoth<T>> captureBoth(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.tail,
      bool captureOut = true,
      bool captureErr = true}) async {
    final capture = CaptureBoth<T>();

    if (captureOut) {
      _capture(sinkOutController, capture.out, maxBuffer, captureMode);
    }

    if (captureErr) {
      _capture(sinkErrController, capture.err, maxBuffer, captureMode);
    }

    /// run the pipeline.
    await _run();
    return capture;
  }

  /// Returns the 'out' stream and discards the 'err'stream.
  /// The [CaptureOut.out] list can hold up to [maxBuffer] elements.
  /// If one or more of the [PipeSection] implements [HasExitCode]
  /// the exitCode of the last [HasExitCode] section is available in the
  /// [CaptureOut] otherwise the exitCode is set to zero.
  /// The [captureMode] controls whether the fist [maxBuffer] elements (head)
  /// or the last [maxBuffer] elements (tail) are returned.
  core.Future<CaptureOut<T>> captureOut(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.tail}) async {
    final capture = CaptureOut<T>();
    _capture(sinkOutController, capture.out, maxBuffer, captureMode);
    await _run();
    return capture;
  }

  /// Returns the 'err' stream and discards the 'out'stream.
  /// The [CaptureErr.err] list can hold up to [maxBuffer] elements.
  ///
  /// If one or more of the [PipeSection] implements [HasExitCode]
  /// the exitCode of the last [HasExitCode] section is available in the
  /// [CaptureOut] otherwise the exitCode is set to zero.
  /// The [captureMode] controls whether the fist [maxBuffer] elements (head)
  /// or the last [maxBuffer] elements (tail) are returned.
  Future<CaptureErr<T>> captureErr(
      {int maxBuffer = 10000,
      CaptureMode captureMode = CaptureMode.tail}) async {
    final capture = CaptureErr<T>();
    _capture(sinkErrController, capture.err, maxBuffer, captureMode);

    await _run();
    return capture;
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

  /// Runs the pipeline returning the last [n] lines of the output.
  /// If you choose to capture err and out then they are mixed in the
  /// list in the order the pipeline outputs them.
  /// If any of the [PipeSection]s returns an non-zero exit code then an
  /// exception is thrown.
  Future<List<T>> tail(int n,
          {bool captureOut = true, bool captureErr = false}) async =>
      (await captureMixed(
              maxBuffer: n, captureErr: captureErr, captureOut: captureOut))
          .mixed;

  /// Runs the pipeline returning the fist [n] lines of the output.
  /// This is actually the default mode of [captureOut] but we include
  /// this method for symmetry with the tail method.
  /// If any of the [PipeSection]s returns an non-zero exit code then an
  /// exception is thrown.
  Future<List<T>> head(int n,
          {bool captureOut = true, bool captureErr = false}) async =>
      (await captureMixed(
              maxBuffer: n, captureErr: captureErr, captureOut: captureOut))
          .mixed;

  /// Runs the pipeline printing the out stream to stdout and the
  /// err stream to stderr.
  /// If the streams are a `List<int>` we automatically
  /// convert it to a `List<String>`
  ///
  /// If one of the [PipeSection]s runs a Command then exit code from the
  /// last one is returned otherwise 0 is returned.
  Future<int> printmix({bool showStdout = true, bool showStderr = true}) async {
    if (T == List<int>) {
      sections.add(TransformerPipeSection<List<int>, String>(Transform.line));
    }

    sections.add(BlockPipeSection(plumber: (plumbing) async {
      if (showStdout) {
        plumbing.src.listen(core.print);
      }
      if (showStderr) {
        plumbing.srcErr.listen((data) => io.stderr.write(data));
      }
    }));

    return _run();
  }

  /// Runs the pipeline printing the out stream to stdout.
  /// If the stream is a `List<int>` we automatically
  /// convert it to a `List<String>`
  /// The error stream is supressed.
  ///
  /// If one of the [PipeSection]s runs a Command then exit code from the
  /// last one is returned otherwise 0 is returned.
  Future<int> print() async => printmix(showStderr: false);

  /// Runs the pipeline printing the err stream to stderr.
  /// If the stream is a `List<int>` we automatically
  /// convert it to a `List<String>`
  ///
  /// If one of the [PipeSection]s runs a Command then exit code from the
  /// last one is returned otherwise 0 is returned.
  Future<int> printerr() async => printmix(showStdout: false);

  /// The output of the final phase is funnelled into
  /// these two controllers.
  /// Each [PipePhase] declares this pair but
  /// only the final phase uses them.
  /// We delcare them here so that they can inherit
  /// there <T> from the  final [PipePhase] that
  /// actually users them.
  final sinkOutController = StreamControllerEx<T>(debugName: 'final: out');
  final sinkErrController = StreamControllerEx<T>(debugName: 'final err');
  final dummyStdErr =
      StreamControllerEx<List<int>>(debugName: 'dummy stdin - error channel');

  // Wire up the [PipeSection]s by attaching their streams
  // and then run the pipeline.
  Future<int> _run() async {
    Object? firstException;
    StackTrace? firstStackTrace;

    await withStdin(debugName: 'stdin of main process',
        (stdinController) async {
      /// Wire the process's stdin as the first
      /// section's input
      StreamControllerEx<dynamic> priorOutController = stdinController;

      /// The first section has no error inputs so wire in
      /// an empty stream.
      StreamControllerEx<dynamic> priorErrController = dummyStdErr;

      // wire each section running
      for (final section in sections) {
        await section.initStreams(
          priorOutController,
          priorErrController,
        );

        await section.addPlumbing();

        priorOutController = section.sinkController;
        priorErrController = section.sinkErrController;
      }

      /// Wire up the final section's output and error
      /// streams to the final sinks.
      priorOutController.stream
          .listen((data) => sinkOutController.add(data as T));
      priorErrController.stream
          .listen((data) => sinkErrController.add(data as T));

      // start each section running
      for (final section in sections) {
        section.done = section.start();
      }

      /// Wait for all sections to complete.
      for (final section in sections) {
        log.fine(() => 'waiting for section: ${section.debugName} to complete');

        try {
          if (firstException == null) {
            /// As soon as one section throws we stop waiting on
            /// subsequent sections as we need to shut down the
            /// pipeline and clean up.
            await section.done;
          }
          // ignore: avoid_catches_without_on_clauses
        } catch (e, st) {
          firstException = e;
          firstStackTrace = st;
        }
        log.fine(() => 'section ${section.debugName} completed');
        await section.close();
      }

      await Future.delayed(Duration.zero, () {});

      /// A controller will not close if it has any listeners
      /// or it has never been listened to.
      if (stdinController.hasListener) {
        await stdinController.close();
      }
      if (sinkOutController.hasListener) {
        await sinkOutController.close();
      }

      if (sinkErrController.hasListener) {
        await sinkErrController.close();
      }
    });

    /// A section threw, so now we have shutdown the pipeline
    /// lets re-throw it.
    if (firstException != null) {
      Error.throwWithStackTrace(firstException!, firstStackTrace!);
    }

    var exitCode = 0;
    for (final section in sections) {
      if (section is HasExitCode) {
        exitCode = (section as HasExitCode).exitCode;
      }
    }

    _dispose();

    return exitCode;
  }

  void _dispose() {
    // we are being discared so close the controllers
    unawaited(sinkOutController.close());
    unawaited(sinkErrController.close());
    unawaited(dummyStdErr.close());
  }

  /// Each time another [PipeSection] is added to the pipeline
  /// we need to change the type of the [PipePhase] to match
  /// so we create a new [PipePhase] and discared the old
  /// one.
  PipePhase<O> _changeType<O>(PipePhase<T> src) {
    final out = PipePhase<O>(src._halfPipe2)..sections = src.sections;
    _dispose();
    return out;
  }

  // core.Future<core.int> run() async => _run();

  // Stream<T> get stdout => sinkOutController.stream;

  /// This is a Terminal method which causes the pipeline to run
  ///
  /// Delivers a stream of errors reported by sections of the
  /// pipeline. If you have [CommandPipeSection]s then you
  /// must call them with nothrow:true otherwise the first
  /// error will shut the pipeline down.
  // Stream<T> get stderr => sinkErrController.stream;

  // Future<Stream<T>> get stdmix async => mixStreams(stdout, stderr);

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
}
