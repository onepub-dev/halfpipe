// ignore_for_file: avoid_returning_this

import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../processors/processor.dart';
import '../util/stream_controller_ex.dart';
import 'pipe_section.dart';

class ProcessorPipeSection<I, O> extends PipeSection<I, O> {
  ProcessorPipeSection(this.processor);

  Processor<I, O> processor;

  @override
  CompleterEx<void> get done => processor.done;

  @override
  Future<void> start(
          StreamControllerEx<I> srcIn, StreamControllerEx<I> srcErr) async =>
      processor.start(srcIn, srcErr);

  @override
  String get debugName => 'processor';
}
