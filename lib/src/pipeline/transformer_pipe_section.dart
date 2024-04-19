// ignore_for_file: avoid_returning_this

import '../transformers/transformer.dart';
import 'dart:async';
import 'dart:io';
import 'pipe_section.dart';

class TransformerPipeSection extends PipeSection {
  TransformerPipeSection(this.transformer);

  Transformer transformer;

  @override
  Future<void> process(
      Stream<List<String>> stdin, IOSink stdout, IOSink stderr) async {
    transformer.process(stdin, stdout, stderr);
  }
}
