import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import '../util/stream_controller_ex.dart';
import 'processor.dart';

class ReadFile extends Processor<List<int>, List<int>> {
  ReadFile(this.pathToFile);
  String pathToFile;

  @override
  final done = CompleterEx<void>(debugName: 'ReadFile');

  @override
  Future<void> start(
    StreamControllerEx<List<int>> srcIn,
    StreamControllerEx<List<int>> srcErr,
  ) async {
    // Read the file as a list of strings
    final ras = File(pathToFile).open();

    /// write the contents of the file into the stream.
    ras.asStream().listen((event) {
      stdout.write(event);
    })
      ..onDone(done.complete)
      ..onError(done.completeError);

    await errController.sink.addStream(srcErr.stream);
  }

  @override
  String get debugName => 'readfile';
}
