import 'dart:async';

import '../pipeline/pipe_section.dart';
import '../processors/processor.dart';

/// A Transformer is a type of [PipeSection] that can transform
/// data. Any transformation is allowed including injecting additional
/// data, removing data, agregating data or simply changing it.
/// Any errors are written to stderr.
/// [Transformer]s can also change the data type as it is processed
/// by (for example) converting a src type Binary into a sink type of String.
///
/// If the data type between src and sink isn't changing then use a [Processor].
/// HalfPipe ships with a number of standard Transformers but you
/// can write additional [Transformer]s.
abstract class Transformer<I, O> extends PipeSection<I, O> {
  @override
  Future<void> start(
    Stream<I> srcIn,
    Stream<I> srcErr,
  );
}
