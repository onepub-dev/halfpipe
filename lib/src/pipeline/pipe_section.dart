// ignore_for_file: avoid_returning_this, comment_references

import 'dart:async';

import 'package:meta/meta.dart';

import '../util/stream_controller_ex.dart';
import 'pipe_section_mixin.dart';

// ignore: one_member_abstracts
abstract class PipeSection<I, O> with PipeSectionMixin<O> {
  late final StreamControllerEx<I> src;
  late final StreamControllerEx<I> srcErr;

  /// The future retuned by the call to [start]
  /// When [done] complets the [PipeSection] has finished
  /// processing data.
  late final Future<void> done;

  /// Called by the pipe line to give each section a chance
  /// to wire up any listeners before any data is pumped through
  /// the pipeline.
  /// This [PipeSection] must NOT send any data until [start] is called.
  /// [src] is a stream from the prior [PipeSection] equivalent stdout.
  /// [srcErr] is a stream from the prior [PipeSection] equivalent to stderr.
  /// Whilst this method returns a [Future] and delay needs to be short
  /// lived as it will stop the pipeline from starting. Any long running
  /// tasks should be done in [start].

  @nonVirtual
  Future<void> initStreams(
    StreamControllerEx<I> src,
    StreamControllerEx<I> srcErr,
  ) async {
    this.src = src;
    this.srcErr = srcErr;
  }

  Future<void> addPlumbing();

  /// After calling [initStreams], this method is called to start this section.
  /// If this [PipeSection] only transforms data then the [start]
  /// method doesn't need to do anything.
  /// If this [PipeSection] is generates data then it should start doing
  /// so when [start] is called.
  /// If [start] processes data then it should return a Future which
  /// completes when it has finished processing all data.
  Future<void> start();

  /// Called when the pipeline is shutting down to give each
  /// section a chance to free any resources.
  ///
  @override
  Future<void> close();
}
