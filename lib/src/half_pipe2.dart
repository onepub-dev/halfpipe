// ignore_for_file: avoid_returning_this

import 'dart:async';
import 'dart:io';

import 'pipeline/command_pipe_section.dart';
import 'pipeline/pipe_section.dart';
import 'pipeline/processor_pipe_section.dart';
import 'pipeline/transformer_pipe_section.dart';
import 'transformers/transformer.dart';

typedef Processor = Future<void> Function(
    Stream<List<String>> stdin, IOSink stdout, IOSink stderr);

class HalfPipe2 {
  HalfPipe2 command(String command, [List<String>? args]) {
    sections.add(CommandPipeSection(command, args: args));
    return this;
  }

  List<PipeSection> sections = [];

  /// Defines a block of dart code that can is called as
  /// part of the pipeline.
  HalfPipe2 processor(Processor callback) {
    sections.add(ProcessorPipeSection(callback));

    return this;
  }

  ///
  HalfPipe2 transformer(Transformer transformer) {
    sections.add(TransformerPipeSection(transformer));
    return this;
  }

  /// redirect the processors output
  HalfPipe2 redirectStdout(Redirect redirect) => this;
  HalfPipe2 redirectStderr(Redirect redirect) => this;

  /// Runs the pipeline outputing the results to a list.
  /// If the list exceeds [maxBuffer] then any further
  /// data will be dropped
  /// TODO: support a mode where we keep the last [maxBuffer] lines
  List<String> toList([int maxBuffer = 10000]) {
    final lines = <String>[];

    sections.add(ProcessorPipeSection((stdin, stdout, stderr) async {
      stdin.listen((lineList) {
        lines.addAll(lineList);
        // Remove excess lines beyond maxBuffer
        while (lines.length >= maxBuffer) {
          lines.removeAt(0);
        }
        // Add the new line
      });
    }));

    /// run the pipeline.
    _run();
    return lines;
  }

  // Wire up the [PipeSection]s by attaching their streams
  // and then run the pipeline.
  void _run() {}
}

enum Redirect { toStdout, toStderr, toDevNull }
