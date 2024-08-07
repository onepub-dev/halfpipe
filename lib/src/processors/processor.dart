import '../pipeline/pipe_section.dart';
import '../transformers/transformer.dart';

/// A Processor is a type of [PipeSection] that can transform
/// data.
/// Any transformation is allowed including injecting additional
/// data, removing data, agregating data or simply changing it.
/// Any errors are written to stderr.
/// HalfPipe ships with a number of standard Transformers but you
/// can write additional [Processor]s.

abstract class Processor<I, O> extends Transformer<I, O> {}
