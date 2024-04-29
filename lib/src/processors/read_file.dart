import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';

import 'processor.dart';

class ReadFile extends Processor<List<int>, List<int>> {
  ReadFile(this.pathToFile);
  String pathToFile;

  @override
  Future<CompleterEx<void>> start(
    Stream<List<int>> srcIn,
    Stream<List<int>> srcErr,
  ) async {
    // Read the file as a list of strings
    final ras = File(pathToFile).open();

    final done = CompleterEx<void>(debugName: 'ReadFile');

    /// write the contents of the file into the stream.
    ras.asStream().listen((event) {
      stdout.write(event);
    })
      ..onDone(done.complete)
      ..onError(done.completeError);

    await errController.sink.addStream(srcErr);

    return done;
  }

  @override
  StreamController<List<int>> get errController =>
      StreamController<List<int>>();

  @override
  StreamController<List<int>> get outController =>
      StreamController<List<int>>();
}
