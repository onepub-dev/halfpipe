// ignore_for_file: avoid_returning_this, strict_raw_type

import 'dart:async';
import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:async/async.dart';

import '../half_pipe.dart';
import '../processors/processor.dart';
import 'block_pipe_section.dart';
import 'command_pipe_section.dart';
import 'pipe_section.dart';
import 'processor_pipe_section.dart';
import 'transformer_pipe_section.dart';

/// Describes the type of data <T> that the pipeline
/// is holding at then end of a [PipeSection].
/// As data move through the pipeline it's type may
/// be translated a number of times.
/// All pipelines start with int data.
class PipePhase<T> {
  PipePhase(this._halfPipe2);

  final HalfPipe _halfPipe2;

  /// TODO: how do I handle the types as each [PipeSection] could
  /// be a different type.
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
    return _changeType<T, List<int>>(this);
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
    return _changeType<T, int>(this);
  }

  /// Defines a block of dart code that can is called as
  /// part of the pipeline.
  PipePhase<O> block<O>(Block<T, O> callback) {
    sections.add(BlockPipeSection<T, O>(callback));

    return _changeType<T, O>(this);
  }

  ///
  PipePhase<O> processor<O>(Processor<T, O> processor) {
    sections.add(ProcessorPipeSection(processor));
    return _changeType<T, O>(this);
  }

  PipePhase<O> transform<O>(Converter<T, O> converter) {
    sections.add(TransformerPipeSection<T, O>(converter));

    return _changeType<T, O>(this);
  }

  PipePhase<T> write(String pathToFile) {
    final fileSink = File(pathToFile).openWrite();
    return block<T>((srcIn, srcErr, sinkOut, sinkErr) async {
      srcIn.listen(fileSink.write, onDone: fileSink.close);
      await sinkErr.addStream(srcErr);
    });
  }

  //////////////////////////////////////////////////////
  // The following are terminal functions
  // After they are called no additional sections
  // can be added to the pipeline.
  //////////////////////////////////////////////////////

  /// Runs the pipeline outputing the results to a list.
  /// If the list exceeds [maxBuffer] then any further
  /// data will be dropped
  /// TODO: support a mode where we keep the last [maxBuffer] lines
  Future<List<T>> toList([int maxBuffer = 10000]) async {
    final elements = <T>[];

    sinkOutController.stream.cast<T>().listen((data) {
      if (elements.length < maxBuffer) {
        // Add the new data
        elements.add(data);
      }
    });

    /// run the pipeline.
    await run();
    return elements;
  }

  Future<String> toParagraph([int maxBuffer = 10000]) async {
    final list = await toList(maxBuffer);
    return list.join('\n');
  }

  /// redirect the processors output
  PipePhase<T> redirectStdout(Redirect redirect) => this;
  PipePhase<T> redirectStderr(Redirect redirect) => this;

  /// Runs the pipeline printing stdout and stderr
  /// to the console.
  Future<void> printmix(
      {bool showStdout = true, bool showStderr = true}) async {
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

  Future<void> print() async {
    await printmix(showStderr: false);
  }

  Future<void> printerr() async {
    await printmix(showStdout: false);
  }

  // TODO(bsutton): fix this
  Future<int> exitCode() async => 1;

  /// The output of the final phase is funnelled into
  /// these two controllers.
  StreamController<T> sinkOutController = StreamController<T>();
  StreamController<T> sinkErrController = StreamController<T>();

  // Wire up the [PipeSection]s by attaching their streams
  // and then run the pipeline.
  Future<void> run() async {
    final stdinController = StreamController<dynamic>();
    var priorOutController = stdinController;

    stdin.listen((data) => stdinController.sink.add(data));

    /// The first section has no error inputs so wire in
    /// an empty stream.
    var priorErrController = StreamController<dynamic>();
    // final controllersToClose = <StreamController<dynamic>>[];

    late StreamController<dynamic> nextOutController;
    late StreamController<dynamic> nextErrController;

    final sectionCompleters = <Future>[];

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];

      if (i < sections.length - 1) {
        nextOutController = sections[i].outController;
        nextErrController = sections[i].errController;
      } else {
        // If we are on the last section then
        // wire it to the final output controllers
        nextOutController = sinkOutController;
        nextErrController = sinkErrController;
      }
      // ignore: close_sinks
      // final nextIn = StreamController<dynamic>();
      // ignore: close_sinks
      // final nextErr = StreamController<dynamic>();
      // controllersToClose.addAll([nextIn, nextErr]);

      final sectionCompleter = section.start(
          priorOutController.stream,
          priorErrController.stream,
          nextOutController.sink,
          nextErrController.sink);
      sectionCompleters.add(sectionCompleter);

      priorOutController = nextOutController;
      priorErrController = nextErrController;

      // priorSrcIn = nextIn.stream;
      // priorSrcErr = nextErr.stream;
    }

    /// TODO: work out when to close these. We can't do it until all the data
    /// has been processed.
    // for (final controller in controllersToClose) {
    //   await controller.close();
    // }
    // await stdinController.close();

    /// Wait for all sections to process the data through.
    await Future.wait(sectionCompleters);
  }

  PipePhase<O> _changeType<I, O>(PipePhase<I> src) {
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

    // TODO: not certin if this is correct.
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
