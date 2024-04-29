import 'dart:async';

import 'package:completer_ex/completer_ex.dart';

import '../pipeline/pipe_section.dart';

/// A [TransformerBinary] is a type of [PipeSection] that can transform
/// data. Any transformation is allowed including injecting additional
/// data, removing data, agregating data or simply changing it.
/// Any errors are written to stderr.
/// HalfPipe ships with a number of standard Transformers but you
/// can write additional [TransformerBinary]s.
abstract class TransformerBinary extends PipeSection<List<int>, List<int>> {
  @override
  Future<CompleterEx<void>> start(
      Stream<List<int>> srcIn, Stream<List<int>> srcErr);
}
