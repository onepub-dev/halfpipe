import 'dart:async';
import 'dart:convert';

import 'package:completer_ex/completer_ex.dart';

import 'transformer.dart';
import 'utf8_line_splitter.dart';

class Transform<I, O> extends Transformer<I, O> {
  Converter<I, O> converter;

  final _done = CompleterEx<void>(debugName: 'Transform');

  Transform(this.converter);

  @override
  Future<void> addPlumbing() async {
    src.stream.transform(converter).listen((event) {
      sinkController.sink.add(event);
    }, onDone: ()  {
      // onError may already have called completed
      if (!_done.isCompleted) {
        _done.complete();
      }
    }, onError: _done.completeError);
  }

  @override
  Future<void> start()  => _done.future;

  /// A built in transformer that can converts the
  /// int stream that calling a command line app will
  /// produce, into a stream of string lines.
  /// ```dart
  ///  await HalfPipe()
  ///        .command('df -h')
  ///        .transform(Transform.line)
  ///      .block<String>((srcIn, srcErr, stdout, stderr) async {
  ///         await for (final line in srcIn) {
  ///         print('Found: $line');
  ///       }
  ///  }).exitCode();
  static Utf8LineSplitter get line => Utf8LineSplitter();

  @override
  String get debugName => 'transform';
}
