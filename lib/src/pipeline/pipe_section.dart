// ignore_for_file: avoid_returning_this, comment_references

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'pipe_section_mixin.dart';

// ignore: one_member_abstracts
abstract class PipeSection<I, O> with PipeSectionMixin<O> {
  /// Called by the pipe line to give each section a chance
  /// to wire up any listeners before any data is pumped through
  /// the pipeline.
  /// This [PipeSection] must NOT send any data until [start] is called.
  /// [srcIn] is a stream from the prior [PipeSection] equivalent stdout.
  /// [srcErr] is a stream from the prior [PipeSection] equivalent to stderr.
  void wire(
    StreamControllerEx<I> srcIn,
    StreamControllerEx<I> srcErr,
  );

  /// After calling [wire], this method is called to start this section.
  /// If this [PipeSection] only transforms data then the [start]
  /// method doesn't need to do anything.
  /// If this [PipeSection] is generates data then it should start doing
  /// so when [start] is called.
  void start();

  // /// The [done] completer 'completes' when this section has finished
  // /// processing data from its input streams;
  // CompleterEx<void> get done;

  Future<void> get waitUntilOutputDone;

  /// Called when the pipeline is shutting down to give each
  /// section a chance to free any resources.
  ///
  @override
  Future<void> close();
}
