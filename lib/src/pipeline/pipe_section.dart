// ignore_for_file: avoid_returning_this, comment_references

import 'dart:async';

import '../util/stream_controller_ex.dart';

// ignore: one_member_abstracts
abstract class PipeSection<I, O> {
  StreamControllerEx<O> get outController;

  StreamControllerEx<O> get errController;

  /// Runs the defined action passing in data from the previous [PipeSection]
  /// and passing data out to the next [PipeSection].
  /// [srcIn] is a stream from the prior [PipeSection] equivalent stdout.
  /// [srcErr] is a stream from the prior [PipeSection] equivalent to stderr.
  /// [outController] is where this [PipeSection] writes it's 'good' data.
  /// [errController] is where this [PipeSection] writes its 'bad'data.
  /// A Future is returned that completes when this [PipeSection] has completed
  /// generating/processing the [srcIn] and [srcErr] streams.
  Future<CompleterEx<void>> start(Stream<I> srcIn, Stream<I> srcErr);
}
